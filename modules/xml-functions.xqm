xquery version "3.0";

module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions";
import module namespace functx="http://www.functx.com";

declare namespace json="http://www.json.org";

declare variable $xml-functions:mapping-definitions := doc("../mappings/mappings.xml");

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

declare function xml-functions:apply-xsls($mapping as xs:string, $xml as node(), $xsls as xs:string*) as node(){
    let $xml := 
        for $xsl in $xsls
            let $xsl-doc := doc("../mappings/" || $mapping || "/" || $xsl)
            return transform:transform($xml, $xsl-doc, ())
(:        let $log := util:log("INFO", $xsl-uri):)
    return $xml
};

declare function xml-functions:replace-template-variables($template-string as xs:string, $mapping-definition as node(), $line as node()) as xs:string {
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

