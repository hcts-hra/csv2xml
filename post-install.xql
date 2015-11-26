xquery version "1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace xml-functions="http://hra.uni-heidelberg.de/ns/csv2vra/xml-functions" at "modules/xml-functions.xqm";
import module namespace functx="http://www.functx.com";

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(: create the tmp collection :)
local:mkcol(functx:substring-after-last($xml-functions:temp-dir, "/"), functx:substring-before-last($xml-functions:temp-dir, "/")),
sm:chmod($xml-functions:temp-dir, "rwxrwxrwx")