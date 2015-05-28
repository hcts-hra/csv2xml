xquery version "3.0";

module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions";
import module namespace functx="http://www.functx.com";

declare function xml-functions:replace-template-variables($template-string as xs:string, $mapping-definition as node(), $line as node()) as xs:string {
    let $changeFrom :=
        for $mapping in $mapping-definition//mapping/@key/string()
        return
            "\$" || $mapping || "\$"
    
    let $changeTo :=
        for $mapping in $mapping-definition//mapping/string()
            let $queryString := $mapping
            return 
                util:eval($queryString)
    
    let $changeFrom := ($changeFrom)
    let $changeTo := ($changeTo)
    
    let $return :=
        functx:replace-multi($template-string, $changeFrom, $changeTo)
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

