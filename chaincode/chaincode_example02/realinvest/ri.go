package realinvest

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// RIchain :
type RIchain struct{}

// Init : initial method
func (t *RIchain) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("RealInvest chaincode ready to serve")
	return shim.Success(nil)
}

// Invoke Function to capture INVOKE or QUERY chaincode request
func (t *RIchain) Invoke(stub shim.ChaincodeStubInterface) pb.Response {

	function, args := stub.GetFunctionAndParameters()
	fmt.Println("Invoking Transaction :" + function + "")

	if function == "AddInvestor" {

		// Adding Investor in the network
		return t.addInvestor(stub, args)

	} else if function == "AddDeveloper" {

		// adding Developer
		return t.addDeveloper(stub, args)

	} else if function == "CreateProject" {

		// to create a new project in the chain
		return t.createProject(stub, args)

	} else if function == "InvestOrBuy" {

		// Processing Project investments
		return t.investOrBuy(stub, args)

	} else if function == "SellInvestment" {

		// Selling investments for profit/lose
		return t.sellInvestment(stub, args)

	} else if function == "UpdateRate" {

		// Selling investments for profit/lose
		return t.updateRateForProject(stub, args)

	} else if function == "OwnProperty" {

		// Purchase of property
		return t.ownProperty(stub, args)

	}
	return shim.Error("Filed to recognise the transaction type")
}

// ConvertionFunc :
func ConvertionFunc(iType Investor, dType Developer, iargs string, dargs string, iBytes []byte, dBytes []byte, operation string) (Investor Investor, Developer Developer, invBytes []byte, devBytes []byte, err error) {
	//(Investor , Developer , invBytes , devBytes , err error) {
	switch operation {
	case "s-i-j":
		participant := iType
		err = json.Unmarshal([]byte(iargs), &participant)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		return participant, dType, nil, nil, nil
	case "s-d-j":
		participant := dType
		err = json.Unmarshal([]byte(dargs), &participant)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		return iType, participant, nil, nil, nil
	case "b-i":
		participant := iType
		err = json.Unmarshal(iBytes, &participant)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		return participant, dType, nil, nil, nil
	case "b-d":
		participant := dType
		err = json.Unmarshal(dBytes, &participant)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		return iType, participant, nil, nil, nil
	case "i-b":
		participant := iType
		invBytes, err := json.Marshal(participant)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		return iType, dType, invBytes, nil, nil
	case "d-b":
		participant := dType
		devBytes, err := json.Marshal(participant)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		return iType, dType, nil, devBytes, nil
	case "b-i-d":
		investor := iType
		err = json.Unmarshal(iBytes, &investor)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		developer := dType
		err = json.Unmarshal(dBytes, &developer)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		return investor, developer, nil, nil, nil
	case "i-d-b":
		investor := iType
		investorBytes, err := json.Marshal(investor)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		developer := dType
		devBytes, err := json.Marshal(developer)
		if err != nil {
			return iType, dType, nil, nil, err
		}
		return investor, developer, investorBytes, devBytes, nil
	}
	err = errors.New("invalid Operation")
	return iType, dType, nil, nil, err

}

//
//// G E T    A D D  I N V E S T O R      I N F O R M A T I O N
//
func (t *RIchain) addInvestor(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expexting single json string of investor details")
	}
	se := shim.Error
	investor, _, _, _, err := ConvertionFunc(Investor{}, Developer{}, args[0], "", nil, nil, "s-i-j")
	if err != nil {
		return shim.Error("Filaed to parse Investor Details , Error :" + err.Error())
	}
	_, _, investorBytes, _, err := ConvertionFunc(investor, Developer{}, "", "", nil, nil, "i-b")
	if err != nil {
		return se("failed to marshal the investor , Error: " + err.Error())
	}
	err = stub.PutState(investor.ID, investorBytes)
	if err == nil {
		return shim.Error("Failed to Update the Network for adding Investor")
	}
	return shim.Success([]byte(stub.GetTxID()))
}

//
//// G E T    A D D  D E V E L O P E R     I N F O R M A T I O N
//
func (t *RIchain) addDeveloper(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expexting single json string of Developer details")
	}
	_, developer, _, _, err := ConvertionFunc(Investor{}, Developer{}, "", args[0], nil, nil, "s-d-j")
	if err != nil {
		return shim.Error("Filaed to parse Developer Details , Error :" + err.Error())
	}
	_, _, _, developerBytes, err := ConvertionFunc(Investor{}, developer, "", "", nil, nil, "d-b")
	if err != nil {
		return shim.Error("failed to marshal the Developer , Error: " + err.Error())
	}
	err = stub.PutState(developer.DeveloperID, developerBytes)
	if err == nil {
		return shim.Error("Failed to Update the Network for adding Developer")
	}
	return shim.Success([]byte(stub.GetTxID()))
}

//
//// G E T    C R E A T E  P R O J E C T    I N F O R M A T I O N
//
func (t *RIchain) createProject(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expexting single json string of Project details")
	}
	project := Project{}
	err := json.Unmarshal([]byte(args[0]), &project)
	if err != nil {
		return shim.Error("Failed to convert Project details")
	}
	devBytes, err := stub.GetState(project.DeveloperID)
	if err != nil {
		return shim.Error("Failed to get the Developer information for this Project")
	}
	if devBytes == nil {
		return shim.Error("No information available for developer id : " + project.DeveloperID)
	}
	_, developer, _, _, err := ConvertionFunc(Investor{}, Developer{}, "", "", nil, devBytes, "b-d")
	if err != nil {
		return shim.Error("failed to convert bytes to Developer , Error: " + err.Error())
	}
	developer.Projects = append(developer.Projects, project.ProjectID)
	project.CurrentRatePerSqft = project.RatePerSqft
	_, _, _, developerBytes, err := ConvertionFunc(Investor{}, developer, "", "", nil, nil, "d-b")
	if err != nil {
		return shim.Error("Failed to convert developer to bytes , Error : " + err.Error())
	}
	projectBytes, err := json.Marshal(project)
	if err != nil {
		return shim.Error("Failed to convert Project details to bytes")
	}
	err = stub.PutState(project.ProjectID, projectBytes)
	if err != nil {
		return shim.Error("failed to update the Project into the Network")
	}
	err = stub.PutState(developer.DeveloperID, developerBytes)
	if err != nil {
		return shim.Error("failed to update the developer info into the Network")
	}
	return shim.Success([]byte(stub.GetTxID()))
}

//
//// G E T    I N V E S T     I N F O R M A T I O N
//
func (t *RIchain) investOrBuy(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expexting single json string of Investment details")
	}
	investment := Investment{}
	err := json.Unmarshal([]byte(args[0]), &investment)
	if err != nil {
		return shim.Error("Failed to Parse  Investment Details")
	}
	projectBytesfromNtwrk, err := stub.GetState(investment.ProjectCode)
	if err != nil {
		return shim.Error("Failed to get the Project information ")
	}
	if projectBytesfromNtwrk == nil {
		return shim.Error("No information available for Project id : " + investment.ProjectCode)
	}
	project := Project{}
	err = json.Unmarshal(projectBytesfromNtwrk, &project)
	if err != nil {
		return shim.Error("Failed to parse Project information")
	}
	invBytes, err := stub.GetState(investment.InvestorID)
	if err != nil {
		return shim.Error("Failed to get the Investor information for this Project")
	}
	if invBytes == nil {
		return shim.Error("No information available for Investor id : " + investment.InvestorID)
	}
	investor, _, _, _, err := ConvertionFunc(Investor{}, Developer{}, "", "", invBytes, nil, "b-i")
	if err != nil {
		return shim.Error("failed to convert bytes to Developer , Error: " + err.Error())
	}
	if investment.SqftBought > project.RemainingUnits {
		return shim.Error("Cannot buy more than remaining units left in the Project")
	}
	if investment.InvestorType == "Investor" {
		investor.Investments = append(investor.Investments, investment.ProjectCode)
		project.SqftSold = project.SqftSold + investment.SqftBought
		project.RemainingUnits = project.RemainingUnits - investment.SqftBought
		project.Investments = append(project.Investments, investment.InvestmentID)
		project.GrossAmountEarned = project.GrossAmountEarned + investment.Amount
	} else if investment.InvestorType == "Owner" {
		investor.OwnedProperties = append(investor.OwnedProperties, investment.ProjectCode)
		project.SqftSold = project.SqftSold + investment.SqftBought
		project.RemainingUnits = project.RemainingUnits - investment.SqftBought
		owner := Owners{
			OwnerID:     investment.InvestorID,
			Sqft:        investment.SqftBought,
			TotalAmount: investment.Amount,
			SoldDate:    investment.PurchaseDate,
		}
		project.Owners = append(project.Owners, owner)
		project.GrossAmountEarned = project.GrossAmountEarned + investment.Amount
	} else {
		return shim.Error("Transaction is neither an 'Investment' nor a 'Purchase'")
	}
	projectBytes, err := json.Marshal(project)
	if err != nil {
		return shim.Error("Failed to convert Project details to bytes")
	}
	investorBytes, err := json.Marshal(investor)
	if err != nil {
		return shim.Error("Failed to convert investor details to bytes")
	}
	investmentBytes, err := json.Marshal(investment)
	if err != nil {
		return shim.Error("Failed to convert investment details to bytes")
	}
	err = stub.PutState(project.ProjectID, projectBytes)
	if err != nil {
		return shim.Error("failed to update the Project into the Network")
	}
	err = stub.PutState(investor.ID, investorBytes)
	if err != nil {
		return shim.Error("failed to update 'Investor' into the Network")
	}

	err = stub.PutState(investment.InvestmentID, investmentBytes)
	if err != nil {
		return shim.Error("failed to add the 'Investment'  into the Network")
	}
	return shim.Success(nil)
}

//
//// C H A N G E    R A T E / S Q F T    O F    P R O J E C T
//
func (t *RIchain) updateRateForProject(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expexting single json string of ChangeRate details")
	}
	changeRate := struct {
		ProjectID   string  `json:"projectID"`
		RatePerSqft float64 `json:"ratePerSqft"`
	}{}
	err := json.Unmarshal([]byte(args[0]), &changeRate)
	if err != nil {
		return shim.Error("Failed to Parse  ChangeRate Details")
	}
	projectBytesfromNtwrk, err := stub.GetState(changeRate.ProjectID)
	if err != nil {
		return shim.Error("Failed to get the Project information ")
	}
	if projectBytesfromNtwrk == nil {
		return shim.Error("No information available for Project id : " + changeRate.ProjectID)
	}
	project := Project{}
	err = json.Unmarshal(projectBytesfromNtwrk, &project)
	if err != nil {
		return shim.Error("Failed to parse Project information")
	}
	project.CurrentRatePerSqft = changeRate.RatePerSqft
	projectBytes, err := json.Marshal(project)
	if err != nil {
		return shim.Error("Failed to convert Project details to bytes")
	}
	err = stub.PutState(project.ProjectID, projectBytes)
	if err != nil {
		return shim.Error("failed to update the Project into the Network")
	}
	return shim.Success([]byte(stub.GetTxID()))
}

//
//// S E L L   I N V E S T M E N T
//
func (t *RIchain) sellInvestment(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expecting single json string of 'Selling Investment' details")
	}
	sellInvest := struct {
		InvestmentID string  `json:"investmentID"`
		SellingSqft  float64 `json:"sellingSqft"`
		BuyerID      string  `json:"buyerID"`
		AmountPaid   float64 `json:"amountPaid"`
	}{}
	err := json.Unmarshal([]byte(args[0]), &sellInvest)
	if err != nil {
		return shim.Error("Failed to Parse  SellInvest Details")
	}
	sellingInvestment := Investment{}
	sellingInvestmentBytes, err := stub.GetState(sellInvest.InvestmentID)
	if err != nil {
		return shim.Error("failed to get the Investment from the network" + err.Error())
	}
	if sellingInvestmentBytes == nil {
		return shim.Error("No information found for Investment id : " + sellInvest.InvestmentID)
	}
	err = json.Unmarshal(sellingInvestmentBytes, &sellingInvestment)
	if err != nil {
		return shim.Error("Failed to parse investment From network to investment Type , Error: " + err.Error())
	}
	projectDetails := Project{}
	projectDetailsBytes, err := stub.GetState(sellingInvestment.ProjectCode)
	if err != nil {
		return shim.Error("failed to get the Project from the network" + err.Error())
	}
	if projectDetailsBytes == nil {
		return shim.Error("No information found for Project id : " + sellingInvestment.ProjectCode)
	}
	err = json.Unmarshal(projectDetailsBytes, &projectDetails)
	if err != nil {
		return shim.Error("Failed to parse Project details From network to Project Type , Error: " + err.Error())
	}
	totalAmount := projectDetails.RatePerSqft * sellInvest.SellingSqft
	if sellInvest.AmountPaid != totalAmount {
		return shim.Error("Transaction failed due to Mismatch between selling Rate Per Sqft")
	}
	if sellingInvestment.RemainingSqft < sellInvest.SellingSqft {
		return shim.Error("Transaction failed due to selling more sqft than the remaining sqft in Investment")
	}
	buyingInvestment := Investment{}
	buyingInvestmentBytes, _ := stub.GetState(sellInvest.BuyerID + "_" + sellingInvestment.ProjectCode)
	if buyingInvestmentBytes != nil {
		err = json.Unmarshal(buyingInvestmentBytes, &buyingInvestment)
		if err != nil {
			return shim.Error("Failed to parse investment From network to investment Type , Error: " + err.Error())
		}
	}
	currentDate := time.Now().Local()
	sbid := strings.Replace((strings.Replace(currentDate.String(), " ", "", -1)), ":", "", -1)[:16]
	sbInfo := SellorBuyInvestment{
		SbID:         sbid,
		InvestmentID: sellInvest.InvestmentID,
		SqftSold:     sellInvest.SellingSqft,
		SoldRate:     projectDetails.RatePerSqft,
		BuyerID:      sellInvest.BuyerID,
		TotalAmount:  sellInvest.AmountPaid,
		SoldDate:     currentDate.String(),
	}
	sellingInvestment.RemainingSqft = sellingInvestment.RemainingSqft - sellInvest.SellingSqft
	sellingInvestment.AmountEarnedBySelling = sellingInvestment.AmountEarnedBySelling + sellInvest.AmountPaid
	sellingInvestment.SellOrBuyInfo = append(sellingInvestment.SellOrBuyInfo, sbid)

	buyingInvestment.SqftBought = buyingInvestment.SqftBought + sellInvest.SellingSqft
	buyingInvestment.RemainingSqft = buyingInvestment.RemainingSqft + sellInvest.SellingSqft
	buyingInvestment.SellOrBuyInfo = append(buyingInvestment.SellOrBuyInfo, sbid)

	sellerInvestmentBytes, err := json.Marshal(sellingInvestment)
	if err != nil {
		return shim.Error("Failed to convert sellingInvestment  details to bytes")
	}
	err = stub.PutState(sellingInvestment.InvestmentID, sellerInvestmentBytes)
	if err != nil {
		return shim.Error("failed to update the Selling info into the Network")
	}

	buyerInvestmentBytes, err := json.Marshal(buyingInvestment)
	if err != nil {
		return shim.Error("Failed to convert buyingInvestment  details to bytes")
	}
	err = stub.PutState(buyingInvestment.InvestmentID, buyerInvestmentBytes)
	if err != nil {
		return shim.Error("failed to update the buyingInvestment info into the Network")
	}
	sbInfoBytes, err := json.Marshal(sbInfo)
	if err != nil {
		return shim.Error("Failed to convert Selling  details to bytes")
	}
	err = stub.PutState(sbInfo.SbID, sbInfoBytes)
	if err != nil {
		return shim.Error("failed to update the Selling info into the Network")
	}
	return shim.Success([]byte(stub.GetTxID()))
}

//
////   O W N  P R O P E R T Y
//
func (t *RIchain) ownProperty(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	return shim.Success(nil)
}

//
//// 	M A I N		F U N C T I O N		C H A I N C O D E 		S T A R T S 	H E R E
//

func main() {
	err := shim.Start(new(RIchain))
	if err != nil {
		fmt.Printf("Error starting RealInvest chaincode: %s", err)
	}
}
