package realinvest

// Investor :
type Investor struct {
	ID              string   `json:"ID"`
	Name            string   `json:"name"`
	Address         string   `json:"address"`
	ContactNumber   string   `json:"contactNumber"`
	Investments     []string `json:"investments"`
	OwnedProperties []string `json:"ownedProperties"`
}

// Developer :
type Developer struct {
	DeveloperID   string   `json:"developerID"`
	Name          string   `json:"name"`
	OfficeAddress string   `json:"officeAddress"`
	ContactNumber string   `json:"contactNumber"`
	Projects      []string `json:"projects,omitempty"`
}
