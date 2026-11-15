// Fact_Admissions: Power Query (M) cleaning script
// Healthcare Admissions Dashboard
//
// To use: Home > Transform data > New Source > Blank Query > Advanced Editor > paste.
// Then change FilePath below to where healthcare_dataset.csv is on your computer.
// Expected row counts: 55,500 loaded > 54,966 after duplicates > 54,860 after negative billing.
let
  FilePath = "C:\Data\healthcare_dataset.csv",

  Source = Csv.Document(
    File.Contents(FilePath),
    [Delimiter = ",", Columns = 15, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
  ),

  PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),        // 55,500 rows

  ChangedColumnType = Table.TransformColumnTypes(
    PromotedHeaders,
    {
      {"Name", type text}, {"Age", Int64.Type}, {"Gender", type text},
      {"Blood Type", type text}, {"Medical Condition", type text},
      {"Date of Admission", type date}, {"Doctor", type text},
      {"Hospital", type text}, {"Insurance Provider", type text},
      {"Billing Amount", type number}, {"Room Number", Int64.Type},
      {"Admission Type", type text}, {"Discharge Date", type date},
      {"Medication", type text}, {"Test Results", type text}
    },
    "en-US"
  ),

  // Remove exact duplicate rows (all 15 columns compared, before any column is dropped)
  RemovedDuplicates = Table.Distinct(ChangedColumnType),                             // 54,966 rows

  // Negative billing amounts are invalid for admissions
  ValidBilling = Table.SelectRows(RemovedDuplicates, each [Billing Amount] >= 0),    // 54,860 rows

  // Names (scrambled casing), doctors, hospitals and room numbers are not used
  DropIdentifiers = Table.RemoveColumns(ValidBilling, {"Name", "Doctor", "Hospital", "Room Number"}),

  AddLOS = Table.AddColumn(
    DropIdentifiers, "LOS Days",
    each Duration.Days([Discharge Date] - [Date of Admission]),
    Int64.Type
  ),

  AddAgeGroup = Table.AddColumn(
    AddLOS, "Age Group",
    each if [Age] < 30 then "13-29"
         else if [Age] < 45 then "30-44"
         else if [Age] < 60 then "45-59"
         else if [Age] < 75 then "60-74"
         else "75-89",
    type text
  ),

  AddAgeSort = Table.AddColumn(
    AddAgeGroup, "Age Group Sort",
    each if [Age] < 30 then 1
         else if [Age] < 45 then 2
         else if [Age] < 60 then 3
         else if [Age] < 75 then 4
         else 5,
    Int64.Type
  ),

  AddKey = Table.AddIndexColumn(AddAgeSort, "Admission ID", 1, 1, Int64.Type)
in
  AddKey