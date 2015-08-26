xquery version "3.0";

module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions";
import module namespace functx="http://www.functx.com";

declare namespace json="http://www.json.org";
declare namespace csv2xml="http://hra.uni-hd.de/csv2xml/template";

declare variable $xml-functions:mappings-path := "..";
declare variable $xml-functions:mapping-definitions := doc($xml-functions:mappings-path || "/mappings/mappings.xml");
declare variable $xml-functions:temp-dir := xs:anyURI("/db/tmp/");
declare variable $xml-functions:ERROR := xs:QName("xml-functions:error");

declare function xml-functions:get-catalogs($mapping, $transformation) {
    let $catalogs := doc("../mappings/" || $mapping || "/_mapping-settings.xml")//transformations/transform[@name=$transformation]/validation-catalogs/uri
    return 
        <root>
            {
                for $cat in $catalogs
                return
                    <catalogs json:array="true">
                        <uri>{$cat/string()}</uri>
                        <active>{$cat/@active/string()}</active>
                    </catalogs>
            }
        </root>
};

declare function xml-functions:get-transformations($mapping) {
    let $transformations := doc("../mappings/" || $mapping || "/_mapping-settings.xml")//transformations/transform
    return
        <root>
            {
                for $t in $transformations
                return
                    <transform json:array="true">
                        <name>{$t/@name/string()}</name>
                        <label>{$t/@label/string()}</label>
                        <active>{$t/@active/string()}</active>
                        <selected>{$t/@selected/string()}</selected>
                    </transform>
            }
        </root>    
};

declare function xml-functions:get-xsls($mapping, $transform-name) {
    let $transformations := doc("../mappings/" || $mapping || "/_mapping-settings.xml")//transformations/transform[@name=$transform-name]
(:    let $log := util:log("INFO", doc("../mappings/" || $mapping || "/_mapping-settings.xml")//transformations):)
    return 
        <root>
            {
                for $xsl in $transformations/xsl/uri
                return
                    <xsl json:array="true">
                        <uri>{$xsl/string()}</uri>
                        <active>{$xsl/@active/string()}</active>
                        <selected>{$xsl/@selected/string()}</selected>
                    </xsl>
            }
        </root>
};

declare function xml-functions:apply-xsls($xsls as xs:string*){
(:    let $log := util:log("INFO", "xsls: " || $xsls):)
    let $file-uri := session:get-attribute("file-uri")

    let $transformed-file-uri := functx:substring-before-last($file-uri, ".xml") || "_transformed.xml"
    let $mapping-name := session:get-attribute("mapping-name")
    return 
(:        try {:)
            let $xml := doc($file-uri)
            let $xml :=
                if(count($xsls) > 0) then
                    for $xsl in $xsls
                        let $xsl-doc := doc("../mappings/" || $mapping-name || "/" || $xsl)
                        (: let $log := util:log("INFO", "../mappings/" || $mapping-name || "/" || $xsl):) 
                            return 
                                transform:transform($xml, $xsl-doc, ())
                else
                    $xml
            let $stored-xml-uri := xmldb:store($xml-functions:temp-dir, $transformed-file-uri, $xml)
            return 
                $stored-xml-uri
(:        } catch * {:)
(:            error($xml-functions:ERROR, "XSL-Transforming failed. " || $err:code || " " || $err:description || " " || $err:value):)
(:        }:)
};

declare function xml-functions:replace-template-variables($template-string as xs:string, $mapping-definition as node(), $line as node()) as xs:string {
    let $clear-default-ns := util:declare-namespace("", xs:anyURI(""))
    let $replace-map := 
        map:new(
            for $mapping in $mapping-definition//mapping
                let $key := $mapping/@key/string()
                let $queryString := $mapping/string()
        
                let $changeFrom := "\$" || $key || "\$"
                let $changeTo := util:eval($queryString)
                return
                    map:entry($changeFrom, $changeTo)
        )

    let $from-seq := map:keys($replace-map)
    let $to-seq :=
        for $from in $from-seq
            let $to-value := 
                if ($replace-map($from)) then
                    xs:string($replace-map($from))
                else
                    xs:string("")
            return
                $to-value
    
    let $return :=
        functx:replace-multi($template-string, $from-seq, $to-seq)

    (: remove unreplaced vars :)
    let $return :=
        replace($return, "\$.*?\$", "")
            
    return 
        $return

};

declare function xml-functions:remove-empty-attributes($element as element()) as element() {
    element { node-name($element)}
    {
        $element/@*[string-length(.) ne 0],
        for $child in $element/node( )
            return 
                if ($child instance of element()) then
                    xml-functions:remove-empty-attributes($child)
                else
                    $child
    }
};

declare function xml-functions:remove-empty-elements($nodes as node()*)  as node()* {
   for $node in $nodes
   return
    if ($node instance of element()) then
        if (normalize-space($node) = '') then 
            ()
        else element { node-name($node) }
            { 
                $node/@*,
                xml-functions:remove-empty-elements($node/node())
            }
    else 
        if ($node instance of document-node()) then
            xml-functions:remove-empty-elements($node/node())
        else 
            $node
};

declare function xml-functions:store-parent($parent as node()*) as xs:string{
    let $session-saved-uri := session:get-attribute("file-uri")
(:    let $log := util:log("INFO", session:get-attribute-names()):)
    let $res-name := 
        if ($session-saved-uri) then
            functx:substring-after-last($session-saved-uri, "/")
        else
            util:uuid() || ".xml"
    return 
        try {
            (: if there is already a xnml file for this session, overwrite it:)
            let $store := xmldb:store($xml-functions:temp-dir, $res-name, $parent)
            return
                $res-name
        } catch * {
            error($xml-functions:ERROR, "creating temp file failed", $xml-functions:temp-dir || "/" || $res-name || ":" || $err:code || " " || $err:description || " " || $err:value)
        }
};

declare function xml-functions:store-node($node-as-string as xs:string, $target-node-query){
    let $mapping-name := session:get-attribute("mapping-name")
    (: open temp file :)
    let $generated-doc := doc(session:get-attribute("file-uri"))
    let $xml := parse-xml($node-as-string)
    let $xml := xml-functions:remove-empty-attributes($xml/*)
    
    
    let $importNamespaces := xml-functions:importNamespaces()
    let $target-node := util:eval("$generated-doc//" || $target-node-query)
    return
        try {
            update insert $xml preceding $target-node 
        } catch * {
            error($xml-functions:ERROR, "Error inserting the processed template. " || $err:code || " " || $err:description || " " || $err:value)
        }

(:        util:log("INFO", $generated-doc):)
};


declare function xml-functions:load-templates-in-session() {
    let $mapping-name := session:get-attribute("mapping-name")
    let $settings-uri :=  $xml-functions:mappings-path || "/mappings/" || $mapping-name || "/_mapping-settings.xml"

    (: get the template-filenames:)
    let $settings := doc($settings-uri)
    let $templates := $settings/settings/templates/template

    (: serialize each template :)
    let $templates-strings := 
        map:new(
            for $template in $templates
                let $target-node-query := $template/targetNode/string()
                let $template-filename := $template/filename/string()

                (: load the XML templates :)
                let $xml-uri := $xml-functions:mappings-path || "/mappings/" || $mapping-name || "/templates/" || $template-filename
(:                let $log := util:log("INFO", "tfn:" || $xml-uri):)
                let $xml := doc($xml-uri)
                let $xml-string := serialize($xml)
(:                let $log := util:log("INFO", $xml-string):)
                return 
                    map:entry($template-filename, 
                        map{
                                "string": $xml-string,
                                "targetNodeQuery": $target-node-query
                        }
                    )
        )
    let $store-session := session:set-attribute("template-strings", $templates-strings)
    return
        $templates-strings
};

declare function xml-functions:importNamespaces() {
    let $presetDefinition := session:get-attribute("selectedPresetDefiniton")
    let $namespace-declarations := $presetDefinition/importNamespaces
    return
        for $namespace in $namespace-declarations//ns 
            let $prefix := $namespace/@prefix/string()
            let $namespace-uri := xs:anyURI($namespace/string())
(:            let $log := util:log("INFO", "declaring namespace " || $prefix || ":" || $namespace-uri):)
            return
                try {
                    util:declare-namespace($prefix, $namespace-uri)
                } catch * {
                    error($xml-functions:ERROR, "Error declaring namespace " || $prefix || ":" || $namespace-uri || " - " || $err:code || " " || $err:description || " " || $err:value)
                }
};

declare function xml-functions:get-mapping-settings() {
    let $mapping-name := session:get-attribute("mapping-name")
    return
        if (not(session:get-attribute("mapping-settings"))) then
            let $settings-uri :=  $xml-functions:mappings-path || "/mappings/" || $mapping-name || "/_mapping-settings.xml"
            let $settings := doc($settings-uri)
            let $session-store := session:set-attribute("mapping-settings", $settings)
            return 
                $settings
        else
            session:get-attribute("mapping-settings")
};

declare function xml-functions:count-pagination-items() as xs:integer {
    let $import-namespaces := xml-functions:importNamespaces()
    let $presetDefinition := session:get-attribute("selectedPresetDefiniton")
    let $pagination-query := $presetDefinition/paginationQuery/string()
    let $log := util:log("INFO", "paginationQuery" || $pagination-query)
    
    let $generated-xml := doc(session:get-attribute("transformed-filename"))
    return
        util:eval("count(" || $pagination-query || ")")

};

declare function xml-functions:get-pagination-item($page as xs:integer) {
    let $mapping-name := session:get-attribute("mapping-name")
    let $presetDefinition := session:get-attribute("selectedPresetDefiniton")
    let $pagination-query := $presetDefinition/paginationQuery/string()
    
    
    let $generated-xml := doc(session:get-attribute("transformed-filename"))
    let $importNamespaces := xml-functions:importNamespaces()
    let $page-item := util:eval($pagination-query || "[" || $page || "]")
    return
        $page-item
};