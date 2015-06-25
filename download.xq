xquery version "3.0";

let $parameters :=     
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/xml"/>
        <output:prefix-attributes value="yes"/>
    </output:serialization-parameters>
let $header := 
    (
        response:set-header("Content-Type", "text/xml"),
        response:set-header("Content-Disposition", "attachment; filename=converted.xml")
    )   

return
    session:get-attribute("xml")
