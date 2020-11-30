xquery version "3.0";
import module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions" at "/db/apps/csv2xml/modules/xml-functions.xqm";
declare namespace csv2xml="http://hra.uni-hd.de/csv2xml/template";


(:declare default element namespace "http://www.vraweb.org/vracore4.htm";:)
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
let $test := util:declare-namespace("", xs:anyURI("http://www.vraweb.org/vracore4.htm"))
(::)
let $doc := doc("/db/tmp/adaf9ecf-d529-46c0-b843-3736df1530f4.xml")
return
    $doc//*:image/@id/string()

(:    util:eval("$doc//work/@id")[count(./string()) > 1]:)
(: $doc:)
(:    util:eval("$doc/vra:vra/*"):)
(:let $generated-xml := doc("/db/tmp/cf3c13e0-5392-4937-8501-3b4b4b4116c8_transformed.xml"):)
(:return :)
(:    $generated-xml//csv2xml:*:)
(:    for $node in $generated-xml//csv2xml:*:)
(:    return:)
(:        update delete $node:)
(:    $generated-xml/*/*:Description:)
