xquery version "3.0";

import module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions" at "modules/xml-functions.xqm";
import module namespace csv="http://hra.uni-heidelberg.de/ns/hra-csv2vra/csv" at "modules/csv.xqm";
import module namespace functx="http://www.functx.com";

declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare variable $local:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;


let $action := request:get-parameter("action", "generate")
let $debug :=  request:get-parameter("debug", false())
let $mapping-name := request:get-parameter("mapping", "default")

return
    switch ($action)
        case "reset" return
            let $clearSession := session:invalidate()
            let $header := response:set-header("Content-Type", "application/json")
            return 
                serialize(<result>true</result>, $local:json-serialize-parameters) 
        (: save selected catalogs in Session:)
        case "saveSelectedCatalogs" return
            let $catalogs := request:get-parameter("selectedCatalogs", "")
(:            let $session := session:set-attribute("selectedCatalogs", $catalogs):)
            return
                true()
        case "getSelectedCatalogs" return
            let $catalogs := request:get-parameter("selectedCatalogs", "")
            let $header := response:set-header("Content-Type", "application/json")
            return 
                serialize($catalogs, $local:json-serialize-parameters) 

        case "getCatalogs" return
            let $catalogs := xml-functions:get-catalogs($mapping-name)
            let $header := response:set-header("Content-Type", "application/json")
            return
                serialize($catalogs, $local:json-serialize-parameters)

        case "getTransformations" return
            let $trans := xml-functions:get-transformations($mapping-name)
            let $header := response:set-header("Content-Type", "application/json")
            return
                serialize($trans, $local:json-serialize-parameters)

        case "getXSLs" return
            let $transformation := request:get-parameter("transformation", "")
            let $xsls := xml-functions:get-xsls($mapping-name, $transformation)
            let $header := response:set-header("Content-Type", "application/json")
            return
                serialize($xsls, $local:json-serialize-parameters)
            
            
        case "getInfo" return
            let $data := session:get-attribute("data")
(:            let $useless := util:log("DEBUG", $self-id-url || " " || $remote-id-url):)
            let $header := response:set-header("Content-Type", "application/json")
            let $result :=
                <info>
                    <lines>{count($data/line)}</lines>
                </info>
            return
                serialize($result, $local:json-serialize-parameters)

        case "upload" return
            let $file-name := request:get-uploaded-file-name('file')
            let $file-data := request:get-uploaded-file-data('file')
            
            let $fileinfo := contentextraction:get-metadata($file-data)
            let $filetype := substring-before(data($fileinfo//xhtml:meta[@name="Content-Type"]/@content), ";")
            let $file-encoding := $fileinfo//xhtml:meta[@name="Content-Encoding"]/@content/string()
            let $filetype := "text/plain"

            (: check format :)
            return
                switch ($filetype)
                    case "text/plain" return
                        let $csv-string := util:binary-to-string($file-data, $file-encoding)
                        let $csv-parsed := csv:read-csv($csv-string)
                        let $useless := session:set-attribute("data", csv:add-char-index($csv-parsed))
                        return
            (:                $csv-string:)
                            response:redirect-to(xs:anyURI("setup-conversion.xq"))
                    default return
                        <div>Fileformat not supported!</div>

        case "generate" return
            let $data := session:get-attribute("data")
            let $start := xs:integer(request:get-parameter("start", 1))
            let $end := xs:integer(request:get-parameter("end", count($data/line)))
            let $xsls := request:get-parameter("xsls[]", "")
            
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

            (: process each csv line   :)
            let $lines := $data/line[position() > ($start - 1) and position() < ($end + 1) ]
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
            let $output-xml := xml-functions:remove-empty-attributes($output-xml/*)

            let $output-xml :=
                if(not(count($xsls) = 1 and $xsls[1] = '')) then
                    xml-functions:apply-xsls($mapping-name, $output-xml, $xsls)
                else
                    $output-xml
            
            let $session-store := session:set-attribute("xml", $output-xml)
            return
                let $header := response:set-header("Status", "200")
                return
                    if($debug = "true") then
                        $lines
                    else
                        $output-xml
                    
        case "validate" return
            (: get the catalogs for validations :)
            let $reports := 
                for $cat in request:get-parameter("catalogs[]", "")
                    let $clear := validation:clear-grammar-cache()
                    let $catalog-uri := xs:anyURI($cat)
                    let $pre-parse := validation:pre-parse-grammar($catalog-uri)
    (:                let $parsed-grammars := session:set-attribute("validation-grammars", validation:pre-parse-grammar($catalogs)):)
                    let $report :=
                        <report-result>
                            <xsd>{$cat}</xsd>
                            {validation:jaxp-report(session:get-attribute("xml"), true())}
                        </report-result>
                    return 
                        $report
            let $session-store := session:set-attribute("validation-reports", $reports)
            let $valid := 
                if ("invalid" = $reports//status/string()) then
                    "invalid"
                else
                    "valid"
            let $result :=
                <root>
                    <result>
                        {$valid}
                    </result>
                    <reports>
                        {count($reports)}
                    </reports>
                </root>
            let $header := response:set-header("Content-Type", "application/json")
            return
                serialize($result, $local:json-serialize-parameters)
        default return
            ""


(:let $mapping-name := :)
(:    if ($mapping-name = "") then :)
(:        "default":)
(:    else:)
(:        $mapping-name:)



