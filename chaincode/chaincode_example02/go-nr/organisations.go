package main

// "Organisation "
type Organisation struct {
	Class                    string `json:"$class"`
	Doctype                  string `json:"doctype,omitemit"`
	OrganizationID           string `json:"OrganizationID"`
	OrganizationName         string `json:"OrganizationName,omitempty"`
	OrganizationCode         string `json:"OrganizationCode,omitempty"`
	OrganizationType         string `json:"OrganizationType,omitempty"`
	ParentOrganizationID     string `json:"ParentOrganizationID,omitempty"`
	ContactPerson            string `json:"ContactPerson,omitempty"`
	AddressLine1             string `json:"AddressLine1,omitempty"`
	AddressLine2             string `json:"AddressLine2,omitempty"`
	CityName                 string `json:"CityName,omitempty"`
	StateCode                string `json:"StateCode,omitempty"`
	CountyCode               string `json:"CountyCode,omitempty"`
	CountryCode              string `json:"CountryCode,omitempty"`
	ZipCode                  string `json:"ZipCode,omitempty"`
	ContactPhone             string `json:"ContactPhone,omitempty"`
	EmailID                  string `json:"EmailID,omitempty"`
	Fax                      string `json:"Fax,omitempty"`
	WebsiteURL               string `json:"WebsiteURL,omitempty"`
	TIN                      string `json:"TIN,omitempty"`
	CCN                      string `json:"CCN,omitempty"`
	SSN                      string `json:"SSN,omitempty"`
	NPI                      string `json:"NPI,omitempty"`
	EIN                      string `json:"EIN,omitempty"`
	IsInternal               string `json:"IsInternal,omitempty"`
	IsActive                 string `json:"IsActive,omitempty"`
	ProviderCommercialNumber string `json:"ProviderCommercialNumber,omitempty"`
	LocationNumber           string `json:"LocationNumber,omitempty"`
	NCPDPNumber              string `json:"NCPDPNumber,omitempty"`
	OtherIdentifier          string `json:"OtherIdentifier,omitempty"`
	ProviderUPINNumber       string `json:"ProviderUPINNumber,omitempty"`
	StateLicenseNumber       string `json:"StateLicenseNumber,omitempty"`
}
