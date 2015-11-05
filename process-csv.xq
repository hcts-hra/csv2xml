xquery version "3.0";

import module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions" at "modules/xml-functions.xqm";
import module namespace csv="http://hra.uni-heidelberg.de/ns/hra-csv2vra/csv" at "modules/csv.xqm";
import module namespace functx="http://www.functx.com";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace json="http://www.json.org";
declare namespace csv2xml="http://hra.uni-hd.de/csv2xml/template";

declare variable $local:json-serialize-parameters :=
                    
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
    <output:method value="json"/>
    <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;


let $action := request:get-parameter("action", "generate")
let $debug :=  session:get-attribute("debug")
let $mapping-name := session:get-attribute("mapping-name")
let $settings-uri :=  "mappings/" || $mapping-name || "/_mapping-settings.xml"

(: default: send "OK" :)
let $header := response:set-status-code(200)

return
    switch ($action)
        case "reset" return
            let $log := util:log("INFO", "SESSION: resetting")
            let $session-attributes-reset :=
                (
(:                    session:set-attribute("xml", ""),:)
                    session:set-attribute("data", ()),
(:                    session:set-attribute("mapping-name", ""),:)
                    session:set-attribute("mapping-settings", ()),
                    session:set-attribute("namespace-definitions", ()),
                    session:set-attribute("template-strings", ())
                    

                )
(:            let $clearSession := session:invalidate():)
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
            let $trans := request:get-parameter("trans", "")
            let $catalogs := xml-functions:get-catalogs($mapping-name, $trans)
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

        case "loadTemplates" return
            let $templates-strings-map := xml-functions:load-templates-in-session()
            let $result :=
                    <root>
                        {
                        for $template-filename in map:keys($templates-strings-map)
                            return
                                <template json:array="true">
                                    <key>
                                        {$template-filename}
                                    </key>
                                    <!--
                                        <loaded json:literal="true">
                                        </loaded>
                                    -->
                                </template>
                        }
                    </root>
            let $header := response:set-header("Content-Type", "application/json")
            return
                serialize($result, $local:json-serialize-parameters)

        case "validate" return
            (: get the catalogs for validations :)
            let $reports := 
                for $cat in request:get-parameter("catalogs[]", "")
                    let $clear := validation:clear-grammar-cache()
                    let $catalog-uri := xs:anyURI($cat)
                    let $pre-parse := validation:pre-parse-grammar($catalog-uri)
                    let $file-uri := session:get-attribute("transformed-filename")
                    let $xml := doc($file-uri)
                    let $report :=
                        <report-result>
                            <xsd>{$cat}</xsd>
                            {validation:jaxp-report($xml, true())}
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
                
        case "updateMapping" return
            let $mapping-name := request:get-parameter("mapping", "example")
            let $settings-uri :=  "mappings/" || $mapping-name || "/_mapping-settings.xml"

            let $mapping-definition := doc($settings-uri)
            let $uses-headings := $mapping-definition//templates/@uses-headings/string()
            let $session-store := session:set-attribute("mapping-name", $mapping-name)
(:            let $log := util:log("INFO", "SESSION: mapping set: " || session:get-attribute("mapping-name")):)
            (: load Templates :)
            let $loadTemplates := xml-functions:load-templates-in-session()

            let $header := response:set-header("Content-Type", "application/json")
            return
                serialize(<root json:literal="true">{$uses-headings}</root>, $local:json-serialize-parameters)
        
        case "getXML" return
(:            let $max-lines := request:get-parameter("maxLines", ()):)
            let $xml := session:get-attribute("xml")
            let $header := response:set-header("Content-Type", "text/xml")
            return
                $xml
        
        case "storeParent" return
            try {
                    let $settings := doc($settings-uri)
(:                    let $log := util:log("INFO", "settings-uri: " || $settings-uri):)
                    let $parent-template-filename := $settings/settings/templates/parent/string()
        
                    (: get the parent xml wrapper :)
                    let $parent-xml := doc("mappings/" || $mapping-name || "/templates/" || $parent-template-filename)
(:                    let $log := util:log("INFO", "parent-xml: " || "mappings/" || $mapping-name || "/templates/" || $parent-template-filename):)

                    let $resource-name := xml-functions:store-parent($parent-xml)

                    let $session-store-xml-filename := session:set-attribute("file-uri", $xml-functions:temp-dir || "/" || $resource-name)
                    let $header := response:set-header("Content-Type", "application/json")
                    return
                        serialize(<root>{$resource-name}</root>, $local:json-serialize-parameters)
                } catch * {
                    let $response := $err:code || " " || $err:description || " " || $err:value
                    let $header := response:set-status-code(500)
                    return
                        $response
                }
                

        case "processCSVLine" return
            let $mapping-name := session:get-attribute("mapping-name")
            let $csv-line-no := request:get-parameter("line", ())
            let $data := session:get-attribute("data")
            let $templates := session:get-attribute("template-strings")

            let $line-data := $data/line[@num-index=$csv-line-no]
            (: load the defined Mapping:)
            let $csv-map-uri :=  "mappings/" || $mapping-name || "/csv-map.xml"
            let $mapping-definition := doc($csv-map-uri)

            return
                if ($line-data) then
                    try{
                        (: process each template :)
                        let $store-result := 
                            map:for-each-entry($templates, function($key, $template-map){
                                let $template-string := $template-map("string")
                                let $target-node-query := $template-map("targetNodeQuery")
                                let $node-as-string := xml-functions:replace-template-variables($template-string, $mapping-definition, $line-data)
                                (: xml node generated now insert it to temp-file :)
                                let $save := xml-functions:store-node($node-as-string, $target-node-query)

                                return 
                                    true()
                            })
                        let $header := response:set-header("Content-Type", "application/json")
                        return
                            serialize($store-result, $local:json-serialize-parameters)

                    } catch * {
                        let $util := util:log("INFO", "processing line failed")
                        let $header := response:set-status-code(500)
                        return 
                            $err:code || " " || $err:description || " " || $err:value

                    }

                else
                    ()
                    
        case "countPaginationItems" return
            let $result := xml-functions:count-pagination-items()
            let $header := response:set-header("Content-Type", "application/json")
                return
                    serialize(<result json:literal="true">{$result}</result>, $local:json-serialize-parameters)
        
        case "getPaginationItem" return
            let $itemNo := request:get-parameter("itemNo", 1)
            let $result := xml-functions:get-pagination-item($itemNo)
                return
                    $result
        case "generateTransformation" return
            let $xsls := request:get-parameter("xsls[]", ())
            let $header := response:set-header("Content-Type", "application/json")
            return
                try{
                    let $transformed-filename := xml-functions:apply-xsls($xsls)
                    let $session-store := session:set-attribute("transformed-filename", $transformed-filename)
                    let $return :=
                        <root>
                            <xmlFilename>{$transformed-filename}</xmlFilename>
                        </root>
                    return
                        serialize($return, $local:json-serialize-parameters)
                } catch * {
                    let $header := response:set-status-code(500)
                    return 
                        $err:code || " " || $err:description || " " || $err:value
                }

        case "saveSelectedTransPreset" return
            let $selectedPresetName := request:get-parameter("selectedPresetName", ())
(:            let $log := util:log("INFO", $selectedPresetName):)
            return 
                if ($selectedPresetName) then
                    let $mapping-name := session:get-attribute("mapping-name")
                    let $presetDefinition := doc("mappings/" || $mapping-name || "/_mapping-settings.xml")//transformations/transform[@name=$selectedPresetName]
(:                    let $log := util:log("INFO", $presetDefinition):)

                    let $storeSession := session:set-attribute("selectedPresetDefiniton", $presetDefinition)
                    return
                        serialize(<root json:literal="true">true</root>, $local:json-serialize-parameters)
                else
                    ()
        
        case "cleanupXML" return
            let $cleanup := xml-functions:cleanupXML()
            return
                serialize(<root json:literal="true">true</root>, $local:json-serialize-parameters)


        default return
            ""