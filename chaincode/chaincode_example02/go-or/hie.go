/*
Copyright IBM Corp. 2016 All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

		 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

//WARNING - this chaincode's ID is hard-coded in chaincode_example04 to illustrate one way of
//calling chaincode from a chaincode. If this example is modified, chaincode_example04.go has
//to be modified as well with the new ID of chaincode_example02.
//chaincode_example05 show's how chaincode ID can be passed in as a parameter instead of
//hard-coding.
//"github.com/hyperledger/fabric/core/chaincode/shim/ext/cid"

import (
	"fmt"
	"encoding/json"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	//"github.com/hyperledger/fabric/core/chaincode/shim/ext/cid"
)

type HIEChaincode struct {
}

func (t *HIEChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("HIE chaincode ready to serve")
	return shim.Success(nil)
}

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
	} //else if function == "GetAccountDetails" {
	// 	// the old "Query" is now implemtned in invoke
	// 	return t.getAccountDetails(stub, args)
	// } else if function == "GetCustomers" {
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
	fmt.Println(HL7MshDetails.MSHKEY);
	MSHKEYId  := HL7MshDetails.MSHKEY;
	MSHKEYbytes, err := stub.GetState(MSHKEYId)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + MSHKEYId + "\"}"
		return shim.Error(jsonResp)
	}

	if MSHKEYbytes != nil {
		jsonResp := "{\"Error\":\"" + MSHKEYId + "\"Already Exists\"}"
		return shim.Error(jsonResp)
	}
	Hl7MshKeyJSONasBytes, err := json.Marshal(HL7MshDetails)

	err = stub.PutState(HL7MshDetails.MSHKEY, Hl7MshKeyJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	jsonResp := "{\"MshKey\":\"" + HL7MshDetails.MSHKEY + "\",\"\nDetails\":\"" + string(Hl7MshKeyJSONasBytes) + "\"}"
	fmt.Printf("Add MSH KEY Response:%s\n", jsonResp)
	return shim.Success(nil)
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
	//
	//// Checking if Source and Destination organisations are differrent
	//
	if DestOrgDetails.SrcOrganizationID == DestOrgDetails.DestOrganization {
		jsonResp := "{\"Error\":\"Source and Destination organisations are same\"}"
		return shim.Error(jsonResp)
	}
	DestOrgID := ""+DestOrgDetails.MSHKEY+"_"+DestOrgDetails.DestOrganization+""
	fmt.Println(DestOrgID);
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
		Mshkey string `json:"Mshkey"`
		Destkey string `json:"Destkey"`
		Sourceorgkey string `json:"Sourceorgkey"`
	}{
		Mshkey:	DestOrgDetails.MSHKEY,
		Destkey: DestOrgDetails.DestOrganization,
		Sourceorgkey: DestOrgDetails.SrcOrganizationID,
	}
	eventPayloadAsBytes, err := json.Marshal(getMshFromHie)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to Marshal " + getMshFromHie.Mshkey + "\"}"
		return shim.Error(jsonResp)
	}
	err = stub.SetEvent("getMshFromHie",eventPayloadAsBytes)
	fmt.Println("sending event getMshFromHie"+ string(eventPayloadAsBytes)+"");
	jsonResp := "{\"DestOrgID\":\"" + DestOrgDetails.DestOrganization + "\",\"\nDetails\":\"" + string(DestOrgKeyJSONasBytes) + "\"}"
	fmt.Printf("Add DESTINATION ORGANISATION Response:%s\n", jsonResp)
	return shim.Success(nil)
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
	fmt.Println(OrganisationDetails.OrganizationID);
	OrganizationID  := OrganisationDetails.OrganizationID;
	OrganizationIDbytes, err := stub.GetState(OrganizationID)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + OrganizationID + "\"}"
		return shim.Error(jsonResp)
	}

	if OrganizationIDbytes != nil {
		jsonResp := "{\"Error\":\"" + OrganizationID + "\"Already Exists\"}"
		return shim.Error(jsonResp)
	}
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
	return shim.Success(nil)
}

// func (t *HIEChaincode) getCustomers(stub shim.ChaincodeStubInterface, args []string) pb.Response {
// 	var err error

// 	if len(args) != 1 {
// 		return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
// 	}

// 	BankId, err := cid.GetID(stub)
// 	fmt.Println(BankId)
// 	//BankId := "Bank1"
// 	// Get the state from the ledger
// 	Avalbytes, err := stub.GetState(BankId)
// 	if err != nil {
// 		jsonResp := "{\"Error\":\"Failed to get state for " + BankId + "\"}"
// 		return shim.Error(jsonResp)
// 	}

// 	if Avalbytes == nil {
// 		jsonResp := "{\"Error\":\"Nil amount for " + BankId + "\"}"
// 		return shim.Error(jsonResp)
// 	}

// 	jsonResp := "{\"Name\":\"" + BankId + "\",\"Amount\":\"" + string(Avalbytes) + "\"}"
// 	fmt.Printf("Query Response:%s\n", jsonResp)
// 	return shim.Success(Avalbytes)
// }

func main() {
	err := shim.Start(new(HIEChaincode))
	if err != nil {
		fmt.Printf("Error starting CBFT chaincode: %s", err)
	}
}
