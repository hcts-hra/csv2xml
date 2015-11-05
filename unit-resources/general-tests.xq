xquery version "3.0";
import module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions" at "/db/apps/csv2xml/modules/xml-functions.xqm";
declare default element namespace "http://www.vraweb.org/vracore4.htm";
(:let $namespace-declarations := :)
(:    <namespaces>:)
(:        <ns prefix="vra">http://www.vraweb.org/vracore4.htm</ns>:)
(:    </namespaces>:)
(::)
(:let $do-declare :=:)
(:    for $namespace in $namespace-declarations//ns :)
(:        let $prefix := $namespace/@prefix/string():)
(:        let $namespace-uri := xs:anyURI($namespace/string()):)
(:        return:)
(:            util:declare-namespace($prefix, $namespace-uri):)
(::)

let $node := "<bla>asdad</bla>"
(:let $test := util:declare-namespace("", xs:anyURI("http://www.vraweb.org/vracore4.htm")):)
(::)
let $doc := doc("/db/tmp/6339309c-41d4-4b7d-9af1-5051462ee535.xml")
(:return:)
(:    util:eval("$doc/vra:vra/*"):)
let $generated-xml := doc("/db/tmp/cf3c13e0-5392-4937-8501-3b4b4b4116c8_transformed.xml")
return
    doc("../mappings/" || "example" || "/_mapping-settings.xml")/transformations

(:    $generated-xml/*/*:Description:)
