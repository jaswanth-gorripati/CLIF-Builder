package main

//	Participants
//  manufacturer , wholeseller ,  retailer, consumer
// batch number , count of tables transafered, count match between transaction.

// Participant : Participants in the network
type Participant struct {
	Doctype           string   `json:"doctype"`
	Name              string   `json:"name"`
	Ptype             string   `json:"ptype"`
	FaciliytyLocation string   `json:"faciliytyLocation"`
	DrugBatchIds      []string `json:"DrugBatchIds,omitempty"`
}

// Consumer : End users who purchases the drug
type Consumer struct {
	Doctype       string `json:"doctype"`
	ContactNumber string `json:"contactNumber"`
	Name          string `json:"name"`
	Location      string `json:"location"`
}
