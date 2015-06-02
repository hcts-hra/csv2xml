xquery version "3.0";

import module namespace csv="http://hra.uni-heidelberg.de/ns/hra-csv2vra/csv" at "modules/csv.xqm";
import module namespace response="http://exist-db.org/xquery/response";


declare namespace xhtml="http://www.w3.org/1999/xhtml";


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
                response:redirect-to(xs:anyURI("process-csv.xq"))
        default return
            <div>Fileformat not supported!</div>
