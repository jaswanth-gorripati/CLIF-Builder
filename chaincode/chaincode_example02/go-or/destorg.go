package main

type DestOrg struct {
	doctype			  string `json:"$class"`
	MSHKEY            string `json:"MSHKEY"`
	SrcOrganizationID string `json:"srcOrganizationID"`
	DestOrganization 	  string `json:"desOrganizationID"`
}