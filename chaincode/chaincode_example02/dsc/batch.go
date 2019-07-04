package main

// Batch : batche list
type Batch struct {
	Doctype         string `json:"doctype"`
	BNO             string `json:"bno"`
	DrugName        string `json:"drugName"`
	Mg              string `json:"mg"`
	Formula         string `json:"formula"`
	TotalPackets    int64  `json:"quantityInPackets"`
	DrugsPerPackets int64  `json:"DrugsPerPackets"`
	TrackingID      string `json:"trackingID,omitempty"`
}

// TrackBatch : tracking details of Batch
type TrackBatch struct {
	Doctype                  string   `json:"doctype"`
	TrackingID               string   `json:"trackingID"`
	RemainingPackets         int64    `json:"remainingPackets"`
	IndividualDrugsRemaining int64    `json:"IndividualDrugsRemaining"`
	Sold                     int64    `json:"sold"`
	Warehouses               []string `json:"warehouses,omitempty"`
	Retailers                []string `json:"retailers,omitempty"`
}

// WarehouseBatch : warehouse details
type WarehouseBatch struct {
	Doctype          string   `json:"doctype"`
	ID               string   `json:"id"`
	BNO              string   `json:"bno"`
	WarehouseName    string   `json:"warehouseName"`
	Received         int64    `json:"received"`
	RetailerIDs      []string `json:"retailerIDs,omitempty"`
	RemainingPackets int64    `json:"remainingPackets"`
}

// PillsSoldToReceipts : sold to consumer information
type PillsSoldToReceipts struct {
	Receipt    string `json:"receipt"`
	DrugsCount int64  `json:"drugsCount"`
}

// RetailersBatch : retailers tracking
type RetailersBatch struct {
	Doctype               string                `json:"doctype"`
	ID                    string                `json:"id"`
	BNO                   string                `json:"bno"`
	WareHouseID           string                `json:"warehouseID"`
	ReceivedPackets       int64                 `json:"received"`
	IndividualPillsCounts int64                 `json:"individualPillsCounts"`
	PillsSoldToReceipts   []PillsSoldToReceipts `json:"pillsSoldToReceipts,omitempty"`
	RemainingDrugs        int64                 `json:"remainingDrugs,omitempty"`
}
