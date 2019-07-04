package main

import (
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

// Invoke : Invoke functions
func (t *HIEChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("Invoking Transaction")
	function, args := stub.GetFunctionAndParameters()
	if function == "AddMSH" {
		// Make payment of X units from A to B
		return t.addMSH(stub, args)
	} else if function == "Adddestorg" {
		// Deletes an entity from its state
		return t.adddestorg(stub, args)
	} else if function == "Addparticipant" {
		// the old "Query" is now implemtned in invoke
		return t.addparticipant(stub, args)
	} else if function == "queryAllMshKeys" {
		return t.queryAllMshKeys(stub, args)
	} else if function == "queryCompositeMshKeys" {
		return t.queryCompositeMshKeys(stub, args)
	} else if function == "addMshFiles" {
		return t.addMshFiles(stub, args)
	} else if function == "getAllMshFiles" {
		return t.getAllMshFiles(stub, args)
	}
	// 	// the old "Query" is now implemtned in invoke
	// 	return t.getCustomers(stub, args)
	// }

	return shim.Error("Invalid invoke function name. Expecting \"AddMSH\" \"Adddestorg\" \"Addparticipant\"")
}

//
//// A D D I N G    H L 7 M S H   I N T O   N E T W O R K
//
func (t *HIEChaincode) addMSH(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting MSHKEY Detils details")
	}
	// UserID, err := cid.GetID(stub)
	// fmt.Println(UserID)
	//BankId := "Bank1"
	HL7MshDetails := HL7_MSH{}
	fmt.Println(args[0])
	err := json.Unmarshal([]byte(args[0]), &HL7MshDetails)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Println(HL7MshDetails.MSHKEY)
	MSHKEYId := HL7MshDetails.MSHKEY
	MSHKEYbytes, err := stub.GetState(MSHKEYId)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + MSHKEYId + "\"}"
		return shim.Error(jsonResp)
	}

	if MSHKEYbytes != nil {
		jsonResp := "{\"Error\":\"" + MSHKEYId + "\"Already Exists\"}"
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
//// D E S T I N A T I O N    O R G A N I S A T I O N
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
	id, ok, err := cid.GetAttributeValue(stub, "participantId")
	if err != nil {
		return shim.Error(err.Error())
		// There was an error trying to retrieve the attribute
	}
	if !ok {
		fmt.Println("client cretificte does not have participantID  attribute")
		// The client identity does not possess the attribute
	}
	fmt.Println("Id Name from CID: ", id)
	//
	//// Checking if Source and Destination organisations are differrent
	//
	if DestOrgDetails.SrcOrganizationID == DestOrgDetails.DestOrganization {
		jsonResp := "{\"Error\":\"Source and Destination organisations are same\"}"
		return shim.Error(jsonResp)
	}
	DestOrgID := "" + DestOrgDetails.MSHKEY + "_" + DestOrgDetails.DestOrganization + ""
	fmt.Println(DestOrgID)
	DestOrgIDbytes, err := stub.GetState(DestOrgID)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + DestOrgID + "\"}"
		return shim.Error(jsonResp)
	}

	if DestOrgIDbytes != nil {
		jsonResp := "{\"Error\":\"" + DestOrgID + "\"Already Exists\"}"
		return shim.Error(jsonResp)
	}
	//
	//// Checking whether the Source organisation is valid
	//
	OrganizationIDbytes, err := stub.GetState(DestOrgDetails.SrcOrganizationID)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + DestOrgDetails.SrcOrganizationID + "\"}"
		return shim.Error(jsonResp)
	}

	if OrganizationIDbytes == nil {
		jsonResp := "{\"Error\":\"" + DestOrgDetails.SrcOrganizationID + "\"doesnot Exists\"}"
		return shim.Error(jsonResp)
	}
	//
	//// Checking whether the Destnation organisation is valid
	//
	dOrganizationIDbytes, err := stub.GetState(DestOrgDetails.DestOrganization)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + DestOrgDetails.DestOrganization + "\"}"
		return shim.Error(jsonResp)
	}

	if dOrganizationIDbytes == nil {
		jsonResp := "{\"Error\":\"" + DestOrgDetails.DestOrganization + "\"doesnot Exists\"}"
		return shim.Error(jsonResp)
	}
	//
	////  Adding dest key into the network
	//
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
	getMshFromHie := struct {
		Mshkey       string `json:"Mshkey"`
		Destkey      string `json:"Destkey"`
		Sourceorgkey string `json:"Sourceorgkey"`
	}{
		Mshkey:       DestOrgDetails.MSHKEY,
		Destkey:      DestOrgDetails.DestOrganization,
		Sourceorgkey: DestOrgDetails.SrcOrganizationID,
	}
	eventPayloadAsBytes, err := json.Marshal(getMshFromHie)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal " + getMshFromHie.Mshkey + "\"}"
		return shim.Error(jsonResp)
	}
	err = stub.SetEvent("getMshFromHie", eventPayloadAsBytes)
	fmt.Println("sending event getMshFromHie" + string(eventPayloadAsBytes) + "")
	jsonResp := "{\"DestOrgID\":\"" + DestOrgDetails.DestOrganization + "\",\"\nDetails\":\"" + string(DestOrgKeyJSONasBytes) + "\"}"
	fmt.Printf("Add DESTINATION ORGANISATION Response:%s\n", jsonResp)
	return shim.Success([]byte(stub.GetTxID()))
}

//
////   A D D I N G    O R G A N I S A T I O N
//
func (t *HIEChaincode) addparticipant(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting Bank details")
	}
	OrganisationDetails := Organisation{}
	fmt.Println(args[0])
	err := json.Unmarshal([]byte(args[0]), &OrganisationDetails)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Println(OrganisationDetails.OrganizationID)
	OrganizationID := OrganisationDetails.OrganizationID
	OrganizationIDbytes, err := stub.GetState(OrganizationID)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + OrganizationID + "\"}"
		return shim.Error(jsonResp)
	}

	if OrganizationIDbytes != nil {
		jsonResp := "{\"Error\":\"" + OrganizationID + "\"Already Exists\"}"
		return shim.Error(jsonResp)
	}
	OrganisationDetails.Doctype = OrganisationDetails.Class
	OrganisationKeyJSONasBytes, err := json.Marshal(OrganisationDetails)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal " + OrganizationID + "\"}"
		return shim.Error(jsonResp)
	}
	err = stub.PutState(OrganisationDetails.OrganizationID, OrganisationKeyJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	jsonResp := "{\"OrganizationID\":\"" + OrganisationDetails.OrganizationID + "\",\"\nDetails\":\"" + string(OrganisationKeyJSONasBytes) + "\"}"
	fmt.Printf("Add Organisation Response:%s\n", jsonResp)
	return shim.Success([]byte(stub.GetTxID()))
}

//
////  A D D I N G    A L L   O T H E R    F I L E     H A S H E S ....
//

func (t *HIEChaincode) addMshFiles(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting Msh files format")
	}
	mshfilesList := struct {
		MshKey   string `json:MshKey`
		FileType string `json:FileType`
		Hash     string `json:Hash`
	}{}
	err := json.Unmarshal([]byte(args[0]), &mshfilesList)
	if err != nil {
		return shim.Error(err.Error())
	}
	noMshMessage := ""

	ismshbytes, err := stub.GetState(mshfilesList.MshKey)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + mshfilesList.MshKey + "\"}"
		return shim.Error(jsonResp)
	} else if ismshbytes == nil {
		noMshMessage = "Msh Key" + mshfilesList.MshKey + "is not Uploaded into the network, values are stored but may not be available to get details"
	}
	//stub.GetTxTimestamp
	mshFilesbytes, err := stub.GetState("" + mshfilesList.MshKey + "_files")
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + mshfilesList.MshKey + "_files\"}"
		return shim.Error(jsonResp)
	}
	mshFilesUpdate := MSHFiles{}
	if mshFilesbytes == nil {
		mshFilesUpdate.Doctype = "MshFiles"
		mshFilesUpdate.MSHKEY = mshfilesList.MshKey
		errSt, mshFilestemp := getMshFileType(mshFilesUpdate, mshfilesList.FileType, mshfilesList.Hash)
		if errSt != "" {
			return shim.Error("" + mshfilesList.FileType + " is not a file type")
		}
		mshFilesUpdate = mshFilestemp
		fmt.Println(mshFilesUpdate)
	} else {
		err = json.Unmarshal(mshFilesbytes, &mshFilesUpdate)
		errSt, mshFilestemp := getMshFileType(mshFilesUpdate, mshfilesList.FileType, mshfilesList.Hash)
		if errSt != "" {
			return shim.Error("" + mshfilesList.FileType + " is not a file type")
		}
		mshFilesUpdate = mshFilestemp
		fmt.Println(mshFilesUpdate)
	}
	mshfileBytes, err := json.Marshal(mshFilesUpdate)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal MshFiles update\"}"
		return shim.Error(jsonResp)
	}
	err = stub.PutState(""+mshfilesList.MshKey+"_files", mshfileBytes)
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Println("line 307 -> ", mshFilesUpdate)
	jsonResp := "{\"MSHfiles list for \":\"" + mshfilesList.MshKey + "_files updated \"}"
	fmt.Printf("Add MSHfiles Response:%s\n", jsonResp)
	queryString := fmt.Sprintf("{\"selector\":{\"doctype\":\"Destinationorg.Adddestorg\",\"MSHKEY\":\"%s\"}}", mshfilesList.MshKey)
	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Query result state for " + mshfilesList.MshKey + "\"" + string(err.Error()) + "}"
		return shim.Error(jsonResp)
	} else if resultsIterator.HasNext() {
		destResp, err := resultsIterator.Next()
		fmt.Println("337->" + string(destResp.Value))
		if err != nil {
			jsonResp := "{\"Error\":\"Failed to iterate string \"" + string(err.Error()) + "}"
			return shim.Error(jsonResp)
		}
		destOrg := DestOrg{}
		err = json.Unmarshal(destResp.Value, &destOrg)
		if err != nil {
			return shim.Error("Failed to unmarshal iterative string")
		}
		mshFilesEvent := struct {
			Hash     string `json:"hash"`
			Destkey  string `json:"Destkey"`
			FileType string `json:"FileType"`
		}{
			Hash:     mshfilesList.Hash,
			Destkey:  destOrg.DestOrganization,
			FileType: mshfilesList.FileType,
		}
		mshFilesEventAsBytes, err := json.Marshal(mshFilesEvent)
		if err != nil {
			jsonResp := "{\"Error\":\"Failed to Marshal " + mshFilesEvent.Hash + "\"}"
			return shim.Error(jsonResp)
		}
		fmt.Println(" Event Payload " + string(mshFilesEventAsBytes))
		err = stub.SetEvent("getMshFiles", mshFilesEventAsBytes)
		if err != nil {
			jsonResp := "{\"Error\":\"Failed to emit event Error : " + string(err.Error()) + "\"}"
			return shim.Error(jsonResp)
		}
	}
	return shim.Success([]byte(noMshMessage))
}

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
func (t *HIEChaincode) getAllMshFiles(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments , Expecting Msh key")
	}
	mshFilesbytes, err := stub.GetState("" + args[0] + "_files")
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + args[0] + "_files\"}"
		return shim.Error(jsonResp)
	}
	if mshFilesbytes == nil {
		return shim.Error("Msh files for " + args[0] + " does not exists")
	}
	invoker, ok, err := cid.GetAttributeValue(stub, "participantId")
	if err != nil {
		return shim.Error(err.Error())
		// There was an error trying to retrieve the attribute
	}
	if !ok {
		fmt.Println("client cretificte does not have participantID  attribute")
		// The client identity does not possess the attribute
	}
	fmt.Println("Id Name from CID: ", invoker)
	// mshFiles := MSHFiles{}
	// err = json.Unmarshal(mshFilesbytes, &mshFiles)
	// if err != nil {
	// 	return shim.Error(err.Error())
	// }
	mshFilesFrmBytes := MSHFiles{}
	err = json.Unmarshal(mshFilesbytes, &mshFilesFrmBytes)
	if err != nil {
		return shim.Error("Failed to decode Msh files list")
	}
	queryString := fmt.Sprintf("{\"selector\":{\"doctype\":\"Destinationorg.Adddestorg\",\"MSHKEY\":\"%s\"}}", mshFilesFrmBytes.MSHKEY)
	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Query result state for " + mshFilesFrmBytes.MSHKEY + "\"" + string(err.Error()) + "}"
		return shim.Error(jsonResp)
	} else if resultsIterator.HasNext() {
		destResp, err := resultsIterator.Next()
		fmt.Println("431->" + string(destResp.Value))
		if err != nil {
			jsonResp := "{\"Error\":\"Failed to iterate string \"" + string(err.Error()) + "}"
			return shim.Error(jsonResp)
		}
		destOrg := DestOrg{}
		err = json.Unmarshal(destResp.Value, &destOrg)
		if err != nil {
			return shim.Error("Failed to unmarshal iterative string")
		}
		if destOrg.DestOrganization != invoker && destOrg.SrcOrganizationID != invoker {
			return shim.Error("Invoker :" + invoker + " , is not the destination org, cannot proccess request")
		}
	}

	return shim.Success(mshFilesbytes)
}

func (t *HIEChaincode) queryAllMshKeys(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting MSHKEY to query")
	}
	MSHkEY := args[0]
	Avalbytes, err := stub.GetState(MSHkEY)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + MSHkEY + "\"}"
		return shim.Error(jsonResp)
	}

	// if Avalbytes == nil {
	// 	jsonResp := "{\"Error\":\"Nil amount for " + BankId + "\"}"
	// 	return shim.Error(jsonResp)
	// }

	// jsonResp := "{\"Name\":\"" + BankId + "\",\"Amount\":\"" + string(Avalbytes) + "\"}"
	// fmt.Printf("Query Response:%s\n", jsonResp)
	return shim.Success(Avalbytes)
}
func (t *HIEChaincode) queryCompositeMshKeys(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting MSHKEY to query")
	}

	mshIt, err := stub.GetStateByPartialCompositeKey("SendingApplicationNamespaceID~MSHKEY", []string{args[0]})
	if err != nil {
		fmt.Printf("Error getting partial key %s", err)
	}
	defer mshIt.Close()

	var i int
	for i = 0; mshIt.HasNext(); i++ {
		rR, _ := mshIt.Next()
		oT, CKP, _ := stub.SplitCompositeKey(rR.Key)
		jsonResp := "{\" Doctype\":\"" + oT + "\",\"\nMSHKEY\":\"" + CKP[1] + "\",\"\nSENDING APP\":\"" + CKP[0] + "\"}"
		fmt.Printf("From composite key ->:%s\n", jsonResp)
	}
	return shim.Success(nil)
}

func main() {
	err := shim.Start(new(HIEChaincode))
	if err != nil {
		fmt.Printf("Error starting HIE44 chaincode: %s", err)
	}
}
