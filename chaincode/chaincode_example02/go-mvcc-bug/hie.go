package main

import (
	"bytes"
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/core/chaincode/shim/ext/cid"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// HIEChaincode : Smart contract name
type HIEChaincode struct {
}

// Init : initial method
func (t *HIEChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("HIE chaincode ready to serve")
	return shim.Success(nil)
}

// Invoke Function to capture INVOKE or QUERY chaincode request
func (t *HIEChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {

	function, args := stub.GetFunctionAndParameters()
	fmt.Println("Invoking Transaction :" + function + "")

	if function == "AddMSH" {

		// Adding Msh files
		return t.addMSH(stub, args)

	} else if function == "Adddestorg" {

		// To add destination organisation to a specific MSH key
		return t.adddestorg(stub, args)

	} else if function == "Addparticipant" {

		// Add Organisation participant into the network
		return t.addparticipant(stub, args)

	} else if function == "AddMshFiles" {

		// Storing Hashes of all files related to specific MSH key file
		return t.addMshFiles(stub, args)

	} else if function == "queryMshKey" {

		// Query all MSH keys belogs to the invoker
		return t.queryMshKey(stub, args)

	} else if function == "queryMshKeysBySendingID" {

		// Query all Msh keys based on the sending Application
		return t.queryMshKeysBySendingID(stub, args)

	} else if function == "getAllMshFiles" {

		// Query Hashes of all the uploaded files for a particular MSH key
		return t.getAllMshFiles(stub, args)
	} else if function == "queryUsingString" {

		// Query Hashes of all the uploaded files for a particular MSH key
		return t.queryUsingString(stub, args)
	}

	return shim.Error("Invalid invoke function name. Expecting \"AddMSH\" \"Adddestorg\" \"Addparticipant\" \"AddMshFiles\" \"queryMshKeys\" \"queryMshKeysBySendingId\" \"getAllMshFiles\"")
}

/*
*
*
*		G E N E R A L		F U N C T I O N S
*
 */

/*
*	Getting Invoker Name
 */

func getInvokerName(stub shim.ChaincodeStubInterface) (string, pb.Response) {
	id, ok, err := cid.GetAttributeValue(stub, "participantId")
	if err != nil {
		return "", shim.Error(err.Error())
		// There was an error trying to retrieve the attribute
	}
	if !ok {
		fmt.Println("client cretificte does not have participantID  attribute")
		// The client identity does not possess the attribute
		return "", shim.Error("client cretificte does not have participantID  attribute")
	}
	fmt.Println("Invoker Name from CID: ", id)
	return id, shim.Success(nil)
}

/*
*	checkIfExists checks if key is in the ledger
 */
func checkIfExists(stub shim.ChaincodeStubInterface, key string, toEqual bool) ([]byte, pb.Response) {
	respBytes, err := stub.GetState(key)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + key + "\"}"
		return nil, shim.Error(jsonResp)
	}
	if toEqual {
		if respBytes == nil {
			jsonResp := "{\"Error\":\"" + key + "\"doesnot Exists\"}"
			return nil, shim.Error(jsonResp)
		}
	} else {
		if respBytes != nil {
			jsonResp := "{\"Error\":\"" + key + "\"Already Exists\"}"
			return nil, shim.Error(jsonResp)
		}
	}
	return respBytes, shim.Success(nil)
}

/*
*	 Getting Destination Organisation
 */

func getDestOrg(stub shim.ChaincodeStubInterface, MSHKEY string) (string, string, pb.Response) {
	queryString := fmt.Sprintf("{\"selector\":{\"doctype\":\"Destinationorg.Adddestorg\",\"MSHKEY\":\"%s\"}}", MSHKEY)
	resultsIterator, err := stub.GetQueryResult(queryString)
	destOrg := DestOrg{}
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Query result state for " + MSHKEY + "\"" + string(err.Error()) + "}"
		return "", "", shim.Error(jsonResp)
	} else if resultsIterator.HasNext() {

		// IF 'resultsIterator.HasNext()' true , then DestOrg is Added into the ledger
		destResp, err := resultsIterator.Next()
		if err != nil {
			jsonResp := "{\"Error\":\"Failed to iterate string \"" + string(err.Error()) + "}"
			return "", "", shim.Error(jsonResp)
		}

		// Getting Dest Org details from 'destResp'
		err = json.Unmarshal(destResp.Value, &destOrg)
		if err != nil {
			return "", "", shim.Error("Failed to unmarshal iterative string")
		}
	}
	return destOrg.DestOrganization, destOrg.SrcOrganizationID, shim.Success(nil)
}

/*
*	isDS:	Returns true if invoker is Dest/Src organisation of MSH key details
 */

func isDS(stub shim.ChaincodeStubInterface, mshFilesbytes []byte, MSHKEY string, invoker string) (bool, pb.Response) {

	if mshFilesbytes != nil {
		//	Converting MSHfiles bytes to MSHfiles Format
		mshFilesFrmBytes := MSHFiles{}
		err := json.Unmarshal(mshFilesbytes, &mshFilesFrmBytes)
		if err != nil {
			return false, shim.Error("Failed to decode Msh files list")
		}
		MSHKEY = mshFilesFrmBytes.MSHKEY
	}

	//	Getting Destination,Source Organisation name for MSHKEY
	destID, srcID, errResp := getDestOrg(stub, MSHKEY)
	if destID == "" {
		return false, errResp
	}

	//	Throw Error if invoker is has no access
	if destID != invoker && srcID != invoker {
		return false, shim.Error("Invoker :" + invoker + " , is not the destination/Source org of this MSH key, cannot proccess request")
	}

	//	Returns true to give Access
	return true, shim.Success(nil)
}

// =========================================================================================
// getQueryResultForQueryString executes the passed in query string.
// Result set is built and returned as a byte array containing the JSON results.
// =========================================================================================
func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string, invoker string) ([]byte, error) {

	fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing QueryRecords
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		//	Check if invoker has Permission to view MSHFiles
		canAccess, _ := isDS(stub, nil, queryResponse.Key, invoker)
		if canAccess == true {

			// Add a comma before array members, suppress it for the first array member
			if bArrayMemberAlreadyWritten == true {
				buffer.WriteString(",")
			}
			buffer.WriteString("{\"Key\":")
			buffer.WriteString("\"")
			buffer.WriteString(queryResponse.Key)
			buffer.WriteString("\"")

			buffer.WriteString(", \"Record\":")
			// Record is a JSON object, so we write as-is
			buffer.WriteString(string(queryResponse.Value))
			buffer.WriteString("}")
			bArrayMemberAlreadyWritten = true
		}
	}
	buffer.WriteString("]")

	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

	return buffer.Bytes(), nil
}

/*
*
*
*		I N V O K E' S		F U N C T I O N A L I T Y		S T A R T S		F R O M		H E R E
*
 */

//
//// A D D I N G	H L 7-M S H		I N T O		N E T W O R K
//
func (t *HIEChaincode) addMSH(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting MSHKEY Detils details")
	}
	HL7MshDetails := Hl7Msh{}
	fmt.Println(args[0])
	err := json.Unmarshal([]byte(args[0]), &HL7MshDetails)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Println("Got request to add MSH key : " + HL7MshDetails.MSHKEY)

	MSHKEYbytes, err := stub.GetState(HL7MshDetails.MSHKEY)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + HL7MshDetails.MSHKEY + "\"}"
		return shim.Error(jsonResp)
	}

	if MSHKEYbytes != nil {
		jsonResp := "{\"Error\":\"" + HL7MshDetails.MSHKEY + "\"Already Exists\"}"
		return shim.Error(jsonResp)
	}
	HL7MshDetails.Doctype = HL7MshDetails.Class
	Hl7MshKeyJSONasBytes, err := json.Marshal(HL7MshDetails)
	indexName := "SendingApplicationNamespaceID~MSHKEY"
	ivar, err := stub.CreateCompositeKey(indexName, []string{HL7MshDetails.SendingApplicationNamespaceID, HL7MshDetails.MSHKEY})
	if err != nil {
		return shim.Error(err.Error())
	}
	value := []byte{0x00}
	stub.PutState(ivar, value)
	err = stub.PutState(HL7MshDetails.MSHKEY, Hl7MshKeyJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	jsonResp := "{\"MshKey\":\"" + HL7MshDetails.MSHKEY + "\",\"\nDetails\":\"" + string(Hl7MshKeyJSONasBytes) + "\"}"
	fmt.Printf("Add MSH KEY Response:%s\n", jsonResp)
	return shim.Success([]byte(stub.GetTxID()))
}

//
////	A D D I N G		D E S T I N A T I O N		O R G A N I S A T I O N
//
func (t *HIEChaincode) adddestorg(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting Destination org details")
	}

	DestOrgDetails := DestOrg{}
	fmt.Println(args[0])
	err := json.Unmarshal([]byte(args[0]), &DestOrgDetails)
	if err != nil {
		return shim.Error(err.Error())
	}

	// Getting the invoker name
	invoker, isErr := getInvokerName(stub)
	if invoker == "" {
		return isErr
	}

	// Checking if Invoker is the Source Organisation
	if DestOrgDetails.SrcOrganizationID != invoker {
		jsonResp := "{\"Error\":\"Invoker does not match with the Source Organisation ID\"}"
		return shim.Error(jsonResp)
	}

	// Checking if Source and Destination organisations are differrent
	if DestOrgDetails.SrcOrganizationID == DestOrgDetails.DestOrganization {
		jsonResp := "{\"Error\":\"Source and Destination organisations are same\"}"
		return shim.Error(jsonResp)
	}

	DestOrgID := "" + DestOrgDetails.MSHKEY + "_" + DestOrgDetails.DestOrganization + ""
	fmt.Println(DestOrgID)

	DestOrgIDbytes, errResp := checkIfExists(stub, DestOrgID, false)
	if DestOrgIDbytes != nil {
		return errResp
	}

	// Checking whether the Source organisation is valid
	OrganizationIDbytes, errResp := checkIfExists(stub, DestOrgDetails.SrcOrganizationID, true)
	if OrganizationIDbytes == nil {
		return errResp
	}

	// Checking whether the Destnation organisation is valid
	dOrganizationIDbytes, errResp := checkIfExists(stub, DestOrgDetails.DestOrganization, true)
	if dOrganizationIDbytes == nil {
		return errResp
	}

	//  Adding dest key into the network
	DestOrgDetails.Doctype = DestOrgDetails.Class
	DestOrgKeyJSONasBytes, err := json.Marshal(DestOrgDetails)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal " + DestOrgDetails.DestOrganization + "\"}"
		return shim.Error(jsonResp)
	}
	err = stub.PutState(DestOrgID, DestOrgKeyJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	//	Temp struct for Event Payload
	getMshFromHie := struct {
		Mshkey       string `json:"Mshkey"`
		Destkey      string `json:"Destkey"`
		Sourceorgkey string `json:"Sourceorgkey"`
	}{
		Mshkey:       DestOrgDetails.MSHKEY,
		Destkey:      DestOrgDetails.DestOrganization,
		Sourceorgkey: DestOrgDetails.SrcOrganizationID,
	}

	// Converting payload to []bytes
	eventPayloadAsBytes, err := json.Marshal(getMshFromHie)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal " + getMshFromHie.Mshkey + "\"}"
		return shim.Error(jsonResp)
	}

	//	Emitting Event 'getMshFromHie'
	err = stub.SetEvent("getMshFromHie", eventPayloadAsBytes)

	// Chaincode LOG :
	fmt.Println("sending event getMshFromHie with data : " + string(eventPayloadAsBytes) + "")
	jsonResp := "{\"DestOrgID\":\"" + DestOrgDetails.DestOrganization + "\",\"\nDetails\":\"" + string(DestOrgKeyJSONasBytes) + "\"}"
	fmt.Printf("****DESTINATION ORGANISATION Added with below details : ****\n%s\n", jsonResp)

	//	Returning Transaction ID
	return shim.Success([]byte(stub.GetTxID()))
}

//
////   A D D I N G    O R G A N I S A T I O N
//
func (t *HIEChaincode) addparticipant(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting single json string of Organisation details")
	}

	//	Getting Organisation details from args[0] stringified JSON
	OrganisationDetails := Organisation{}
	fmt.Println(args[0])
	err := json.Unmarshal([]byte(args[0]), &OrganisationDetails)
	if err != nil {
		return shim.Error(err.Error())
	}

	//	Check if Organisation already exists, if it exists throw Error
	OrganizationID := OrganisationDetails.OrganizationID
	OrganizationIDbytes, errResp := checkIfExists(stub, OrganizationID, false)
	if OrganizationIDbytes != nil {
		return errResp
	}

	//	Converting Organisation Details to []byte to Update the Ledger
	OrganisationDetails.Doctype = OrganisationDetails.Class
	OrganisationKeyJSONasBytes, err := json.Marshal(OrganisationDetails)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal " + OrganizationID + "\"}"
		return shim.Error(jsonResp)
	}

	//	Adding Organisation details into the ledger
	err = stub.PutState(OrganisationDetails.OrganizationID, OrganisationKeyJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	//	Chaincode LOG:
	jsonResp := "{\"OrganizationID\":\"" + OrganisationDetails.OrganizationID + "\",\"\nDetails\":\"" + string(OrganisationKeyJSONasBytes) + "\"}"
	fmt.Printf("Add Organisation Response:%s\n", jsonResp)

	//	Returning Transaction ID
	return shim.Success([]byte(stub.GetTxID()))
}

//
////  A D D I N G    A L L   O T H E R    F I L E     H A S H E S ....
//

func (t *HIEChaincode) addMshFiles(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting Msh files format in json string")
	}

	// Getting Msh files information from args[0] string
	mshfilesList := struct {
		MshKey   string `json:"MshKey"`
		FileType string `json:"FileType"`
		Hash     string `json:"Hash"`
	}{}
	err := json.Unmarshal([]byte(args[0]), &mshfilesList)
	if err != nil {
		return shim.Error(err.Error())
	}

	// 'noMshMessage' is a warning, If the MshFiles list is updating before Adding respective MSH key
	noMshMessage := ""

	//	Checking if MSHKEY exists, if not print 'noMshMessage' warning
	ismshbytes, err := stub.GetState(mshfilesList.MshKey)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + mshfilesList.MshKey + "\"}"
		return shim.Error(jsonResp)
	} else if ismshbytes == nil {
		noMshMessage = "Msh Key" + mshfilesList.MshKey + "is not Uploaded into the network, values are stored but may not be available to get details"
	}

	// Checking if MSHFiles already exists to update 'noMshMessage' warning
	mshFilesbytes, err := stub.GetState("" + mshfilesList.MshKey + "_files")
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + mshfilesList.MshKey + "_files\"}"
		return shim.Error(jsonResp)
	}
	mshFilesUpdate := MSHFiles{}
	if mshFilesbytes == nil {
		mshFilesUpdate.Doctype = "MshFiles"
		mshFilesUpdate.MSHKEY = mshfilesList.MshKey

		// Getting the updating File type
		errSt, mshFilestemp := getMshFileType(mshFilesUpdate, mshfilesList.FileType, mshfilesList.Hash)
		if errSt != "" {
			return shim.Error("" + mshfilesList.FileType + " is not a file type")
		}
		mshFilesUpdate = mshFilestemp
		fmt.Println(mshFilesUpdate)
	} else {

		// If MSHfiles already exists , Appending value to 'mshFilesUpdate'
		err = json.Unmarshal(mshFilesbytes, &mshFilesUpdate)

		// Getting the updating File type
		errSt, mshFilestemp := getMshFileType(mshFilesUpdate, mshfilesList.FileType, mshfilesList.Hash)
		if errSt != "" {
			return shim.Error("" + mshfilesList.FileType + " is not a file type")
		}
		mshFilesUpdate = mshFilestemp
		fmt.Println(mshFilesUpdate)
	}

	//	Converting MSH files details to []byte
	mshfileBytes, err := json.Marshal(mshFilesUpdate)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal MshFiles update\"}"
		return shim.Error(jsonResp)
	}

	//	Update/Add to the ledger
	err = stub.PutState(""+mshfilesList.MshKey+"_files", mshfileBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	//	Chaincode LOG :
	fmt.Println("line 307 -> ", mshFilesUpdate)
	jsonResp := "{\"MSHfiles list for \":\"" + mshfilesList.MshKey + "_files updated \"}"
	fmt.Printf("Add MSHfiles Response:%s\n", jsonResp)

	//	Getting Destination organisation of the Msh Key to send an Event to the Destination Organisation about the file upload
	destID, _, errResp := getDestOrg(stub, mshfilesList.MshKey)
	if destID == "" {
		return errResp
	}
	//	'getMshFiles' Event Payload
	mshFilesEvent := struct {
		Hash     string `json:"hash"`
		Destkey  string `json:"Destkey"`
		FileType string `json:"FileType"`
	}{
		Hash:     mshfilesList.Hash,
		Destkey:  destID,
		FileType: mshfilesList.FileType,
	}

	//	Converting Event Payload to []byte
	mshFilesEventAsBytes, err := json.Marshal(mshFilesEvent)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal " + mshFilesEvent.Hash + "\"}"
		return shim.Error(jsonResp)
	}

	//	Emitting 'getMshFiles' Event
	err = stub.SetEvent("getMshFiles", mshFilesEventAsBytes)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to emit event Error : " + string(err.Error()) + "\"}"
		return shim.Error(jsonResp)
	}

	//	Chaincode LOG :
	fmt.Println(" Event Payload " + string(mshFilesEventAsBytes))

	//	Returning 'noMshMessage' warning if any
	return shim.Success([]byte(noMshMessage))
}

//
////	Returns updating file type for MSHfiles
//
func getMshFileType(mfu MSHFiles, ftype string, hvalue string) (string, MSHFiles) {
	switch ftype {
	case "PIDhashFile":
		mfu.PIDhashFile = hvalue
		return "", mfu
	case "OBRhashFile":
		mfu.OBRhashFile = hvalue
		return "", mfu
	case "OBXhashFile":
		mfu.OBXhashFile = hvalue
		return "", mfu
	case "PV1hashFile":
		mfu.PV1hashFile = hvalue
		return "", mfu
	case "ORChashFile":
		mfu.ORChashFile = hvalue
		return "", mfu
	default:
		return "error", mfu
	}
}

//
//// getAllMshFiles:	Returns  all the 'Hashes' of uploaded files , for specific Msh Key
//
func (t *HIEChaincode) getAllMshFiles(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting Msh key")
	}
	mshFilesbytes, errResp := checkIfExists(stub, ""+args[0]+"_files", true)
	if mshFilesbytes == nil {
		return errResp
	}
	// Getting the invoker name
	invoker, isErr := getInvokerName(stub)
	if invoker == "" {
		return isErr
	}

	//	Check if invoker has Permission to view MSHFiles
	canAccess, errResp := isDS(stub, mshFilesbytes, "", invoker)
	if canAccess != true {
		return errResp
	}

	//	Returning MSHfiles detail
	return shim.Success(mshFilesbytes)
}

//
////	queryMshKey:	Get Details of specific MSH key
//

func (t *HIEChaincode) queryMshKey(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting MSHKEY")
	}

	// Getting the invoker name
	invoker, isErr := getInvokerName(stub)
	if invoker == "" {
		return isErr
	}

	MSHKEY := args[0]

	//	Get MSHKEY details , verify if MSH key Exists
	MSHbytes, errResp := checkIfExists(stub, MSHKEY, true)
	if MSHbytes == nil {
		return errResp
	}
	HL7MshDetails := Hl7Msh{}
	err := json.Unmarshal(MSHbytes, &HL7MshDetails)
	if err != nil {
		return shim.Error("MSHKEY unmarshal error")
	}

	//	Check if invoker has Permission to view MSHFiles
	canAccess, errResp := isDS(stub, nil, HL7MshDetails.MSHKEY, invoker)
	if canAccess != true {
		return errResp
	}

	// Returns MSH details
	return shim.Success(MSHbytes)
}

//
////	queryMshKeysBySendingID:	Returns MSH keys for SendingApplicationNamespaceID
//

func (t *HIEChaincode) queryMshKeysBySendingID(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting SendingApplicationNamespaceID to query")
	}

	// Getting the invoker name
	invoker, isErr := getInvokerName(stub)
	if invoker == "" {
		return isErr
	}

	//	Getting results from composite key
	mshIt, err := stub.GetStateByPartialCompositeKey("SendingApplicationNamespaceID~MSHKEY", []string{args[0]})
	if err != nil {
		fmt.Printf("Error getting partial key %s", err)
	}
	defer mshIt.Close()
	jsonResp := "["
	for i := 0; mshIt.HasNext(); i++ {
		rR, _ := mshIt.Next()
		oT, CKP, _ := stub.SplitCompositeKey(rR.Key)

		//	Check if invoker has Permission to view MSHFiles
		canAccess, _ := isDS(stub, nil, CKP[1], invoker)
		if canAccess == true {
			jsonResp = jsonResp + "{\" Doctype\":\"" + oT + "\",\"\nMSHKEY\":\"" + CKP[1] + "\",\"\nSENDING APP\":\"" + CKP[0] + "\"},"
		}
	}
	jsonResp = jsonResp + "{}]"

	//	Chaincode LOG :
	fmt.Printf("Response from queryMshKeysBySendingID ->:%s\n", jsonResp)

	// Returning response
	return shim.Success([]byte(jsonResp))
}

//
////	queryUsingString , query  couchdb using the string
//

func (t *HIEChaincode) queryUsingString(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting single query string")
	}

	// Getting the invoker name
	invoker, isErr := getInvokerName(stub)
	if invoker == "" {
		return isErr
	}

	// get Query results
	queryResults, err := getQueryResultForQueryString(stub, args[0], invoker)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

//
//// 	M A I N		F U N C T I O N		C H A I N C O D E 		S T A R T S 	H E R E
//

func main() {
	err := shim.Start(new(HIEChaincode))
	if err != nil {
		fmt.Printf("Error starting HIE chaincode: %s", err)
	}
}
