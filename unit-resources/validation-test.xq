xquery version "3.0";

let $xml := doc("/db/apps/csv2xml/unit-resources/vra-complete-test-valid.xml")
(:let $grammar := doc("/db/apps/csv2xml/mappings/default/schemata/vraCluster.xsd"):)

let $clear := validation:clear-grammar-cache()

(:let $pre-parse := validation:pre-parse-grammar(xs:anyURI("/db/apps/csv2xml/mappings/default/schemata/vraCluster.xsd")):)
(:let $pre-parse := validation:pre-parse-grammar(xs:anyURI("/db/apps/csv2xml/mappings/default/schemata/vra.xsd")):)
let $pre-parse := validation:pre-parse-grammar(xs:anyURI("http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/resources/schemas/vraCluster.xsd"))
 
(:let $log := util:log("INFO", $pre-parse):)

let $grammar-cache :=  validation:show-grammar-cache()

return
    <result>
        <grammar-cache>
            {$grammar-cache}
        </grammar-cache>
        <report>
            {
                validation:jaxp-report($xml, true())
            }
        </report>
    </result>
    
