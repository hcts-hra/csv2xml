xquery version "3.0";
import module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions" at "modules/xml-functions.xqm";
import module namespace functx="http://www.functx.com";

let $mapping-name := "default"
let $data := session:get-attribute("data")
let $debug :=  request:get-parameter("debug", false())

let $mapping-name := 
    if ($mapping-name = "") then 
        "default"
    else
        $mapping-name

(: load the CSV-mapping:)
let $csv-map-uri :=  "mappings/" || $mapping-name || "/csv-map.xml"
let $mapping-definition := doc($csv-map-uri)

(: get the template-filenames:)
let $parent-template-filename := doc($csv-map-uri)/xml/templates/parent/string()
let $template-filenames := doc($csv-map-uri)/xml/templates/template/string()

(: serialize each template :)
let $templates-strings := 
    for $template-filename in $template-filenames
        (: load the XML templates :)
        let $xml-uri := "mappings/" || $mapping-name || "/" || $template-filename
        let $xml := doc($xml-uri)
        let $xml-string := serialize($xml)
        return $xml-string


(:(: process each csv line   :):)
let $lines := $data/line[position() < 10]
let $processed-template :=
    for $line in $lines
        (: process each line and output the string with replaced variables :)
        let $xml-nodes-string := string-join($templates-strings)
        let $xml-nodes := xml-functions:replace-template-variables($xml-nodes-string, $mapping-definition, $line)
        return 
            string-join($xml-nodes)


(: get the parent xml wrapper :)
let $parent-xml := doc("mappings/" || $mapping-name || "/" || $parent-template-filename)
let $parent-string := serialize($parent-xml)
let $output-string := replace($parent-string, "\$PROCESSED_TEMPLATE\$", string-join($processed-template))
let $output-xml := parse-xml($output-string)
return
    if($debug) then
        $lines
    else
        $output-xml
