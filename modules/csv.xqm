xquery version "3.0";

module namespace csv="http://hra.uni-heidelberg.de/ns/hra-csv2vra/csv";

import module namespace functx="http://www.functx.com";

declare variable $csv:debug :=  session:get-attribute("debug");
declare variable $csv:delim :=  ",";

declare function csv:split-line($str){
    for $t in analyze-string($str,'(?<=^|' || $csv:delim ||  ')(\"(?:[^\"]|\"\")*\"|[^' || $csv:delim || ']*)')/fn:match/fn:group 
    return 
        if($t/text()) then 
            replace($t/text(),"^&quot;|&quot;$","") 
        else "" 
};

declare function csv:num-to-char($num as xs:int) {
    let $num := $num - 1
    let $rounds := floor($num div 26)
    return 
        if($rounds > 0) then
            codepoints-to-string(64 + $rounds) || csv:num-to-char(($num mod 26) + 1)
        else
            codepoints-to-string(65 + $num)
};


declare
(:    %templates:wrap:)
function csv:read-csv($csv-string as xs:string) {

(:    let $lines := tokenize($csv-string, "\n"):)
    let $lines := tokenize($csv-string,"[&#13;&#10;]")
    let $lines := filter($lines,function($x){
            $x ne ""
        })

    let $body := $lines
    let $result := 
        <result>
            {
                for $line at $lpos in $body
                return
                    if (string-length(functx:trim($line)) > 0) then
                        let $columns := csv:split-line($line)
                        return
                            <line num-index="{$lpos}">
                                {
                                    for $column at $pos in $columns
                                    return
                                        <column num-index="{$pos}">
                                            {
                                                let $column := functx:replace-multi($column, ('""', "\$"), ('&quot;', "|||amp|||"))
                                                return
                                                    serialize(functx:trim($column))
                                            }
                                        </column>
                                }
                            </line>
                    else
                        ()
            }
        </result>
    return
        $result
};

declare function csv:add-char-index($csv-data as node()*) {
    let $head := $csv-data//line[position() = 1]
    let $output :=
        <csv>
            {
                for $line in $csv-data//line
                let $line-num-index := data($line/@num-index)
                    return
                        <line num-index="{$line-num-index}">
                        {
                            for $column in $line/column
                            let $column-num-index := data($column/@num-index)
                                return
                                    <column num-index="{$column-num-index}" char-index="{csv:num-to-char(xs:integer($column-num-index))}" heading-index="{$head//column[position() = $column-num-index]/string()}">
                                        {
                                            data($column)
                                        }
                                    </column>
                        }
                        </line>
            }
        </csv>
    return 
        $output
};
