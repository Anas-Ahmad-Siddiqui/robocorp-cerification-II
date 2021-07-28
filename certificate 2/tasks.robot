# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocloud.Secrets
Library           RPA.Dialogs
Library           Process
# -

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    credentials
    Open Available Browser  ${secret}[link]

*** Keywords ***
Get orders
    Create Form    Enter the CSV file download link
    Add Text Input    URL    url    https://robotsparebinindustries.com/orders.csv
    &{result}    Request Response
    Download    ${result["url"]}      overwrite=True      # https://robotsparebinindustries.com/orders.csv
    ${orders}=   Read table from CSV    orders.csv
    [Return]    ${orders}

*** Keywords  ***
Close the annoying modal
    Click Button    OK

*** Keywords  ***
Fill the form
    [Arguments]     ${row}
    Select From List By Value   id:head     ${row}[Head]
    Select Radio Button     body     ${row}[Body]
    Input Text  class:form-control    ${row}[Legs]
    Input Text  id:address      ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview

*** Keywords ***
clicking order button
    Click Button    id:order
    Wait Until Element Is Visible   id:receipt

*** Keywords ***
Submit the order
     Wait Until Keyword Succeeds    1 min  0.3 sec    clicking order button

*** Keywords ***
Store the receipt as a PDF file    
    [Arguments]     ${name}
    Wait Until Element Is Visible   id:receipt
    ${html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${html}    ${CURDIR}${/}output${/}receipts${/}${name}.pdf   
    [Return]        ${CURDIR}${/}output${/}receipts${/}${name}.pdf   

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${name}
    Wait Until Element Is Visible   id:robot-preview-image
    Screenshot      id:robot-preview-image      ${CURDIR}${/}output${/}screenshots${/}${name}.png
    [Return]        ${CURDIR}${/}output${/}screenshots${/}${name}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf      ${screenshot}      ${pdf} 
    Close All Pdfs

*** Keywords ***
Go to order another robot
    Click Button    order-another


*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip     ${CURDIR}${/}output${/}receipts     ${CURDIR}${/}output${/}PDFs.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Submit the order
         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
    END
    Create a ZIP file of the receipts
    Terminate All Processes



