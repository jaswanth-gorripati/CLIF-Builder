package realinvest

// Investment :
type Investment struct {
	InvestmentID          string   `json:"investmentID"`
	ProjectCode           string   `json:"projectCode"`
	InvestorID            string   `json:"investorID"`
	InvestorType          string   `json:"investorType"`
	SqftBought            float64  `json:"sqftBought"`
	Amount                float64  `json:"amount"`
	PurchaseDate          string   `json:"purchaseDate"`
	AmountEarnedBySelling float64  `json:"amountEarnedBySelling,omitempty"`
	RemainingSqft         float64  `json:"remainingSqft"`
	SellOrBuyInfo         []string `json:"sellOrBuyInfo,omitempty"`
}

// SellorBuyInvestment :
type SellorBuyInvestment struct {
	SbID         string  `json:"sbID"`
	InvestmentID string  `json:"investmentID"`
	SqftSold     float64 `json:"sqftSold"`
	SoldRate     float64 `json:"soldRate"`
	BuyerID      string  `json:"buyerID"`
	TotalAmount  float64 `json:"totalAmount"`
	SoldDate     string  `json:"soldDate"`
}

// Owners :
type Owners struct {
	OwnerID     string  `json:"owner"`
	Sqft        float64 `json:"sqft"`
	RatePerSqft float64 `json:"ratePerSqft"`
	TotalAmount float64 `json:"totalAmount"`
	SoldDate    string  `json:"soldDate"`
}

// Project :
type Project struct {
	ProjectID            string   `json:"projectID"`
	DeveloperID          string   `json:"DeveloperID"`
	Name                 string   `json:"name"`
	TotalSqfts           float64  `json:"totalSqft"`
	StartDate            string   `json:"startDate"`
	EndDate              string   `json:"endDate"`
	RatePerSqft          float64  `json:"ratePerSqft"`
	EstimatedProjectCost float64  `json:"estimatedProjectCost"`
	SqftSold             float64  `json:"sqftSold"`
	RemainingUnits       float64  `json:"remainingUnits"`
	CurrentRatePerSqft   float64  `json:"currentRatePerSqft,omitempty"`
	Investments          []string `json:"investors,omitempty"`
	Owners               []Owners `json:"owners,omitempty"`
	GrossAmountEarned    float64  `json:"grossAmountEarned,omitempty"`
}
