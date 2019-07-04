package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

//"github.com/hyperledger/fabric/core/chaincode/shim/ext/cid"

//	DSCchain : Drug Suppply Chain

type DSCchain struct{}

// Init : initial method
func (t *DSCchain) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("DSC chaincode ready to serve")
	return shim.Success(nil)
}

// Invoke Function to capture INVOKE or QUERY chaincode request
func (t *DSCchain) Invoke(stub shim.ChaincodeStubInterface) pb.Response {

	function, args := stub.GetFunctionAndParameters()
	fmt.Println("Invoking Transaction :" + function + "")

	if function == "AddParticipant" {

		// Adding Participants in the network
		return t.addParticipant(stub, args)

	} else if function == "AddBatch" {

		// To add new Batch of Drugs
		return t.addBatch(stub, args)

	} else if function == "TransferToWarehouse" {

		// To transfer drugs to Warehouse
		return t.transferToWarehouse(stub, args)

	} else if function == "TransferToRetailer" {

		// To transfer drugs to Warehouse
		return t.transferToRetailer(stub, args)

	} else if function == "GetBatchInfo" {

		// To transfer drugs to Warehouse
		return t.getBatchInfo(stub, args)

	}
	return shim.Error(" Invalid Invoke request expecting : ")
}

//
//// A D D I N G	P A R T I C I P A N T  	I N T O		N E T W O R K
//
func (t *DSCchain) addParticipant(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expecting participant details in stringified json format")
	}
	participant := Participant{}
	err := json.Unmarshal([]byte(args[0]), &participant)
	if err != nil {
		return shim.Error("Parsing incoming data to Paticipant type error," + string(err.Error()))
	}
	participant.Doctype = "Paticipant"
	participantBytes, err := json.Marshal(participant)
	if err != nil {
		return shim.Error("Error while Parsing  Paticipant type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(participant.Name, participantBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of Participant ," + string(err.Error()))
	}
	return shim.Success(nil)
}

//
//// A D D I N G	N E W   B A T C H  	I N T O		N E T W O R K
//
func (t *DSCchain) addBatch(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expecting Batch details in stringified json format")
	}
	batchInfo := Batch{}
	err := json.Unmarshal([]byte(args[0]), &batchInfo)
	if err != nil {
		return shim.Error("Parsing incoming data to Batch type error," + string(err.Error()))
	}
	trackingInfo := TrackBatch{
		Doctype:                  "TrackBatch",
		TrackingID:               batchInfo.BNO + "_" + batchInfo.DrugName + "",
		RemainingPackets:         batchInfo.TotalPackets,
		IndividualDrugsRemaining: batchInfo.TotalPackets * batchInfo.DrugsPerPackets,
		Sold:                     0,
	}
	batchInfo.Doctype = "Batch"
	batchInfo.TrackingID = trackingInfo.TrackingID
	batchInfoBytes, err := json.Marshal(batchInfo)
	fmt.Println("DRUG :" + batchInfo.DrugName)
	if err != nil {
		return shim.Error("Error while Parsing  Batch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(batchInfo.BNO, batchInfoBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of batchInfo ," + string(err.Error()))
	}
	fmt.Println("tracking ID : " + trackingInfo.TrackingID)
	trackingInfoBytes, err := json.Marshal(trackingInfo)
	if err != nil {
		return shim.Error("Error while Parsing  TrackBatch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(trackingInfo.TrackingID, trackingInfoBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of trackingInfo ," + string(err.Error()))
	}

	return shim.Success(nil)
}

//
//// T R A N F E R 	   T O     W A R E H O U S E
//
func (t *DSCchain) transferToWarehouse(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expecting Warehouse transfer details in stringified json format")
	}
	WarehouseTransfer := struct {
		BNO            string `json:"bno"`
		WarehouseID    string `json:"warehouseID"`
		SendingPackets int64  `json:"sendingPackets"`
	}{}
	err := json.Unmarshal([]byte(args[0]), &WarehouseTransfer)
	if err != nil {
		return shim.Error("Parsing incoming data to WarehouseTransfer type error," + string(err.Error()))
	}

	batchInfobytes, err := stub.GetState(WarehouseTransfer.BNO)
	if err != nil {
		return shim.Error("Error while Getting  Batch information from the network ," + string(err.Error()))
	}
	batchInfo := Batch{}
	err = json.Unmarshal(batchInfobytes, &batchInfo)

	wareID := WarehouseTransfer.WarehouseID + "_" + batchInfo.BNO + "_" + batchInfo.DrugName + ""

	trackingInfobytes, err := stub.GetState(batchInfo.BNO + "_" + batchInfo.DrugName + "")
	trackingInfo := TrackBatch{}
	err = json.Unmarshal(trackingInfobytes, &trackingInfo)
	if trackingInfo.RemainingPackets < WarehouseTransfer.SendingPackets {
		return shim.Error("Cannot send the requested Drug as the Quantity is more than the remaining stock")
	}
	// trackingInfo.Sold = trackingInfo.Sold + WarehouseTransfer.SendingPackets
	// trackingInfo.Remaining = trackingInfo.Remaining - WarehouseTransfer.SendingPackets
	trackingInfo.Warehouses = append(trackingInfo.Warehouses, wareID)
	trackingInfo.RemainingPackets = trackingInfo.RemainingPackets - WarehouseTransfer.SendingPackets
	trackingBytes, err := json.Marshal(trackingInfo)
	if err != nil {
		return shim.Error("Error while Parsing  TrackBatch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(trackingInfo.TrackingID, trackingBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of trackingInfo ," + string(err.Error()))
	}
	WarehouseBatch := WarehouseBatch{
		Doctype:          "Warehouse",
		ID:               wareID,
		BNO:              WarehouseTransfer.BNO,
		WarehouseName:    WarehouseTransfer.WarehouseID,
		Received:         WarehouseTransfer.SendingPackets,
		RemainingPackets: WarehouseTransfer.SendingPackets,
	}
	WarehouseBytes, err := json.Marshal(WarehouseBatch)
	if err != nil {
		return shim.Error("Error while Parsing  TrackBatch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(WarehouseBatch.ID, WarehouseBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of WarehouseInfo ," + string(err.Error()))
	}

	return shim.Success(nil)
}

//
//// T R A N F E R 	   T O     R E T A I L E R
//
func (t *DSCchain) transferToRetailer(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expecting Retailer transfer details in stringified json format")
	}
	retailerTransfer := struct {
		WarehouseDrugID string `json:"warehouseDrugID"`
		RetailerID      string `json:"retailerID"`
		SendingPackets  int64  `json:"sendingPackets"`
	}{}
	err := json.Unmarshal([]byte(args[0]), &retailerTransfer)
	if err != nil {
		return shim.Error("Parsing incoming data to RetailerTransfer type error," + string(err.Error()))
	}

	warehouseInfoBytes, err := stub.GetState(retailerTransfer.WarehouseDrugID)
	if err != nil {
		return shim.Error("Error while Getting  Warehouse information from the network ," + string(err.Error()))
	}
	warehouseInfo := WarehouseBatch{}
	err = json.Unmarshal(warehouseInfoBytes, &warehouseInfo)

	if retailerTransfer.SendingPackets > warehouseInfo.RemainingPackets {
		return shim.Error("Cannot processs request as the Quantity of packets sending is more than the Stock available")
	}

	batchInfobytes, err := stub.GetState(warehouseInfo.BNO)
	if err != nil {
		return shim.Error("Error while Getting  Batch information from the network ," + string(err.Error()))
	}
	batchInfo := Batch{}
	err = json.Unmarshal(batchInfobytes, &batchInfo)

	retailID := retailerTransfer.RetailerID + "_" + batchInfo.BNO + "_" + batchInfo.DrugName + ""

	trackingInfobytes, err := stub.GetState(batchInfo.BNO + "_" + batchInfo.DrugName + "")
	if err != nil {
		return shim.Error("Error while Getting  Tracking information from the network ," + string(err.Error()))
	}
	trackingInfo := TrackBatch{}
	err = json.Unmarshal(trackingInfobytes, &trackingInfo)
	trackingInfo.Retailers = append(trackingInfo.Retailers, retailID)

	trackingBytes, err := json.Marshal(trackingInfo)
	if err != nil {
		return shim.Error("Error while Parsing  TrackBatch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(trackingInfo.TrackingID, trackingBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of trackingInfo ," + string(err.Error()))
	}
	warehouseInfo.RetailerIDs = append(warehouseInfo.RetailerIDs, retailID)
	warehouseInfo.RemainingPackets = warehouseInfo.RemainingPackets - retailerTransfer.SendingPackets
	wareBytes, err := json.Marshal(warehouseInfo)
	if err != nil {
		return shim.Error("Error while Parsing  Batch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(warehouseInfo.ID, wareBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of batchInfo ," + string(err.Error()))
	}
	retailersBatch := RetailersBatch{
		Doctype:               "Retailer",
		ID:                    retailID,
		BNO:                   batchInfo.BNO,
		WareHouseID:           warehouseInfo.ID,
		ReceivedPackets:       retailerTransfer.SendingPackets,
		IndividualPillsCounts: retailerTransfer.SendingPackets * batchInfo.DrugsPerPackets,
		RemainingDrugs:        retailerTransfer.SendingPackets * batchInfo.DrugsPerPackets,
	}
	retailersBatchBytes, err := json.Marshal(retailersBatch)
	if err != nil {
		return shim.Error("Error while Parsing  TrackBatch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(retailersBatch.ID, retailersBatchBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of WarehouseInfo ," + string(err.Error()))
	}

	return shim.Success(nil)
}

//
//// S E L L I N G    D R U G    T O    C O N S U M E R
//
func (t *DSCchain) sellDrug(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expecting Retailer transfer details in stringified json format")
	}
	sellingInfo := struct {
		RetailID          string `json:"retailID"`
		TotalDrugsSelling int64  `json:"totalDrugsSelling"`
		ReceiptNumber     string `json:"receiptNumber"`
	}{}
	err := json.Unmarshal([]byte(args[0]), &sellingInfo)
	if err != nil {
		return shim.Error("Parsing incoming data to SellingInfo type error," + string(err.Error()))
	}

	retailInfoBytes, err := stub.GetState(sellingInfo.RetailID)
	if err != nil {
		return shim.Error("Error while Getting  Retail information from the network ," + string(err.Error()))
	}
	retailInfo := RetailersBatch{}
	err = json.Unmarshal(retailInfoBytes, &retailInfo)

	if sellingInfo.TotalDrugsSelling > retailInfo.RemainingDrugs {
		return shim.Error("Cannot processs request as the Quantity of Drugs selling is more than the Stock available")
	}

	batchInfobytes, err := stub.GetState(retailInfo.BNO)
	if err != nil {
		return shim.Error("Error while Getting  Batch information from the network ," + string(err.Error()))
	}
	batchInfo := Batch{}
	err = json.Unmarshal(batchInfobytes, &batchInfo)

	trackingInfobytes, err := stub.GetState(batchInfo.BNO + "_" + batchInfo.DrugName)
	if err != nil {
		return shim.Error("Error while Getting  Tracking information from the network ," + string(err.Error()))
	}
	trackingInfo := TrackBatch{}
	err = json.Unmarshal(trackingInfobytes, &trackingInfo)
	if trackingInfo.IndividualDrugsRemaining < sellingInfo.TotalDrugsSelling {
		return shim.Error("Cannot processs request as the Quantity of Drugs selling is more than the Stock available")
	}
	trackingInfo.Sold = trackingInfo.Sold + sellingInfo.TotalDrugsSelling
	trackingInfo.IndividualDrugsRemaining = trackingInfo.IndividualDrugsRemaining - sellingInfo.TotalDrugsSelling

	trackingBytes, err := json.Marshal(trackingInfo)
	if err != nil {
		return shim.Error("Error while Parsing  TrackBatch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(trackingInfo.TrackingID, trackingBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of trackingInfo ," + string(err.Error()))
	}
	sellingReceipt := PillsSoldToReceipts{
		Receipt:    sellingInfo.ReceiptNumber,
		DrugsCount: sellingInfo.TotalDrugsSelling,
	}
	retailInfo.PillsSoldToReceipts = append(retailInfo.PillsSoldToReceipts, sellingReceipt)
	retailInfo.RemainingDrugs = retailInfo.RemainingDrugs - sellingInfo.TotalDrugsSelling
	retailersBatchBytes, err := json.Marshal(retailInfo)
	if err != nil {
		return shim.Error("Error while Parsing  TrackBatch type to []byte ," + string(err.Error()))
	}
	err = stub.PutState(retailInfo.ID, retailersBatchBytes)
	if err != nil {
		return shim.Error("Error while 'PUTSTATE' of WarehouseInfo ," + string(err.Error()))
	}
	return shim.Success(nil)
}

//
//// G E T    B A T C H    I N F O R M A T I O N
//
func (t *DSCchain) getBatchInfo(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expecting Batch number only")
	}
	totalBatchInfo := struct {
		Batch          Batch
		TrackBatch     TrackBatch
		WarehouseBatch []WarehouseBatch
		RetailersBatch []RetailersBatch
	}{}

	batchInfobytes, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("Error while Getting  Batch information from the network ," + string(err.Error()))
	}
	if batchInfobytes == nil {
		return shim.Error("Batch iD: " + args[0] + " has no information in the network")
	}
	batchInfo := Batch{}
	err = json.Unmarshal(batchInfobytes, &batchInfo)
	totalBatchInfo.Batch = batchInfo

	trackingInfobytes, err := stub.GetState(batchInfo.BNO + "_" + batchInfo.DrugName)
	if err != nil {
		return shim.Error("Error while Getting  Tracking information from the network ," + string(err.Error()))
	}
	trackingInfo := TrackBatch{}
	err = json.Unmarshal(trackingInfobytes, &trackingInfo)
	totalBatchInfo.TrackBatch = trackingInfo

	for _, element := range trackingInfo.Warehouses {
		warehouseInfoBytes, err := stub.GetState(element)
		if err != nil {
			return shim.Error("Error while Getting  Warehouse information from the network ," + string(err.Error()))
		}
		warehouseInfo := WarehouseBatch{}
		err = json.Unmarshal(warehouseInfoBytes, &warehouseInfo)
		totalBatchInfo.WarehouseBatch = append(totalBatchInfo.WarehouseBatch, warehouseInfo)

	}
	for _, element := range trackingInfo.Retailers {
		retailInfoBytes, err := stub.GetState(element)
		if err != nil {
			return shim.Error("Error while Getting  Retail information from the network ," + string(err.Error()))
		}
		retailInfo := RetailersBatch{}
		err = json.Unmarshal(retailInfoBytes, &retailInfo)
		totalBatchInfo.RetailersBatch = append(totalBatchInfo.RetailersBatch, retailInfo)

	}

	totalBatchInfoBytes, _ := json.Marshal(totalBatchInfo)
	return shim.Success(totalBatchInfoBytes)
}

//
//// 	M A I N		F U N C T I O N		C H A I N C O D E 		S T A R T S 	H E R E
//

func main() {
	err := shim.Start(new(DSCchain))
	if err != nil {
		fmt.Printf("Error starting DSC chaincode: %s", err)
	}
}
