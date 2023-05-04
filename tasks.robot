*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the CSV file
    ${orders}=    Get orders
    Loop the orders    ${orders}
    Create a ZIP file of receipt PDF files
    Log    Done.


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Close the annoying modal

Close the annoying modal
    Click Button    I guess so...

Download the CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true

Get orders
    ${orders}=    Read table from CSV    orders.csv    header=true
    RETURN    ${orders}

Loop the orders
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Fill the form    ${order}
    END

Fill the form
    [Arguments]    ${order}
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    Preview
    Submit the order    ${order}[Order number]

Submit the order
    [Arguments]    ${order_number}
    Mute Run On Failure    Click order
    Wait Until Keyword Succeeds    10x    1s    Click order
    ${pdf}=    Store the receipt as a PDF file    ${order_number}
    ${screenshot}=    Take a screenshot of the robot    ${order_number}
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Click Button    order-another
    Close the annoying modal

Click order
    Click Button    Order
    Wait Until Element Is Visible    order-completion    3s

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    order-completion
    ${sales_results_html}=    Get Element Attribute    order-completion    outerHTML
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot}=    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}${order_number}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}

Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip    overwrite=true
