package main

// DestOrg : destination org for msh files
type DestOrg struct {
	Class             string `json:"$class"`
	Doctype           string `json:"doctype,omitemit"`
	MSHKEY            string `json:"MSHKEY"`
	SrcOrganizationID string `json:"srcOrganizationID"`
	DestOrganization  string `json:"desOrganizationID"`
}
