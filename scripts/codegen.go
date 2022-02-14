package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"strings"
)

func main() {
	// open file
	f, err := os.Open("./deploy.csv")
	if err != nil {
		log.Fatal(err)
	}

	// remember to close the file at the end of the program
	defer f.Close()

	houseMap := make(map[string]string)
	houseMap["GENESIS"] = "0"
	houseMap["LUX"] = "1"
	houseMap["X2"] = "2"
	houseMap["SHADOW"] = "3"
	houseMap["COMETS"] = "4"
	houseMap["DEVASTATORS"] = "5"
	houseMap["TERRA"] = "6"
	houseMap["RONIN"] = "7"

	// read csv values using csv.Reader
	csvReader := csv.NewReader(f)
	data, err := csvReader.ReadAll()
	if err != nil {
		log.Fatal(err)
	}

	data = data[1:]

	for i := range data {
		name := data[i][1]
		house := houseMap[data[i][2]]
		numberInHouse := data[i][3]
		weight := strings.ReplaceAll(data[i][4], ".", "")
		if weight == "" {
			weight = "0"
		}
		fmt.Println(fmt.Sprintf(`_saveTomb(%v, "%s", Tomb({
	_initialized: true,
	weight: %s,
	numberInHouse: %s,
	house: %s,
	deployment: deployment({
		hostContract: 0x0000000000000000000000000000000000000000,
		tokenID: 0,
		chainID: 0,
		deployed: false
	})
}));`,
			i+1, name, weight, numberInHouse, house,
		))
		fmt.Println("")
	}
}
