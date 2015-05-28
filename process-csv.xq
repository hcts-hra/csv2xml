xquery version "3.0";
import module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions" at "modules/xml-functions.xqm";
import module namespace functx="http://www.functx.com";

let $mapping-name := "default"
let $data := session:get-attribute("data")

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

let $line := $data/line[position() = 2]

(: process each line and output the string with replaced variables :)
let $xml-nodes := (
    for $string in $templates-strings
        return
           xml-functions:replace-template-variables($string, $mapping-definition, $line)
    )

(: get the parent xml wrapper :)
let $parent-xml := doc("mappings/" || $mapping-name || "/" || $parent-template-filename)
let $parent-string := serialize($parent-xml)

let $output-xml := parse-xml(replace($parent-string, "\$PROCESSED_TEMPLATE\$", string-join($xml-nodes)))
return
    $output-xml


(:(: process each csv line   :):)
(:for $line in $data/line[position() = 1]:)
(:    (: process each column   :):)
(:    for $column in $line/column:)
(:        (: get the variable   :):)
(:        let $query := $mapping-definition/xml/:)
(::)
(:        return:)
(:            $column:)

(: process :)