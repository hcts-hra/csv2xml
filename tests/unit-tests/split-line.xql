xquery version "3.1";

let $delim :=  ","
let $string-1 := "some_filename.jpg,some_imgAccessNo,some_imgVenNo,some_vendor,some local repo name,some_workID,a predefined work title display,some_w_prefTitle,descriptive,some_altTitle,translated,a predefined work agent display,personal,&quot;Marx, Karl&quot;,viaf,49228757,painter,follower of,personal,&quot;Carus, Carl Gustav&quot;,viaf,76085,former owner,possibly by,personal,&quot;Cézanne, Paul&quot;,viaf,39374836,painter,style of,a predefined work cultural context display,French,aat,300111188,Bohemian,aat,300266148,a predefined work date display,creation,2015-07-30,,alteration,-205,,&quot;This drawing was originally part of a sketchbook, now lost, documenting the artist's 2nd trip to Egypt in 1867. Some of the figure's costume elements appear in a painted work of a later date&quot;,&quot;Hardin, Jennifer, &quot;&quot;The Lure of Egypt,&quot;&quot; St. Petersburg: Museum of Fine Arts, 1995&quot;,&quot;Inscribed, on side of table at left, &quot;&quot;El Sueño de la Razon Produce Monstruos&quot;&quot; (The Sleep of Reason Produces Monsters)&quot;,a predefined work location display,Gift of an unknown donor. ,repository,British Museum,corporate,viaf,134857252,accession,Abc blhgggt 178999,London,tgn,7011781,repository,Musée du Louvre,corporate,viaf,130895627,accession,INV 779,Louvre,tgn,7625108,a predefined work material display,beech (wood),aat,300011948,bark cloth,aat,300048116,gampi,aat,300375507,beech (wood),aat,300011948,a predefined work measurements display,site,m2 m2 ,108,area,,,,,,,area of each unit,ft2ft2,1426,area,,,,,,,a predefined work relation display,first related work,counterProofIs,another related work,contextIs,my_w_rightsDisplay,my_w_sourceDisplay,my_w_stateEditionDisplay,a predefined work style period display,Chenghua,aat,300018455,Qianlong,aat,300018486,High Renaissance,aat,300021142,Fluxus,aat,300022168,a predefined work subject display,Achilles is killed by Paris in the temple of Apollo,iconographicTopic,ICONCLASS,94G531,iconoclasm,conceptTopic,aat,300055792,expulsion of Adam and Eve from paradise (Genesis 3:22-24),iconographicTopic,ICONCLASS,71A6,hobbyhorses,descriptiveTopic,aat,descriptiveTopic,Achilles is killed by Paris in the temple of Apollo,iconographicTopic,ICONCLASS,94G531,iconoclasm,conceptTopic,aat,300055792,expulsion of Adam and Eve from paradise (Genesis 3:22-24),iconographicTopic,ICONCLASS,71A6,hobbyhorses,descriptiveTopic,aat,descriptiveTopic,a predefined work technique display,frottage,aat,300053430,drawing (image making),aat,300054196,frottage,aat,300053430,drawing (image making),aat,300054196,my_w_textRefDisplay,a predefined work worktype display,basilica,aat,300215302,fonds,aat,300189759,posters,aat,300027221,a predefined image agent display,personal,Man Ray,viaf,7396101,photographer,my_image_cultContextDisplay,my_image_dateDisplay,This image was captured while the drawing was on exhibition at the Berkeley Art Museum.,my_image_imscriptionDisplay,my_image_locationDisplay,my_image_measurementsDisplay,my_image_relationDisplay,a predefined image rights display,my_image_RightsNotes,copyrighted,my_image_rightsHolder,my_image_rightsText,my_image_sourceDisplay,IMAGE_Source,my_image_stateEditonDisplay,my_image_stylePeriodDisplay,a predefined image subject display,iconoclasm,conceptTopic,aat,300055792,expulsion of Adam and Eve from paradise (Genesis 3:22-24),iconographicTopic,ICONCLASS,71A6,hobbyhorses,descriptiveTopic,aat,descriptiveTopic,my_image_techniqueDisplay,my_image_textrefDisplay,a predefined image title display,mirror on back wall,generalView,my_image_worktypeDisplay"
let $string-2 := 'Sachin,,M,\"Maths,Science,English\",Need to improve in these subjects.,'

return
    for $record in analyze-string($string-1, '("(?:[^"]|"")*"|[^,"\n\r]*)(,|\r?\n|\r)')/fn:match/fn:group[@nr = '1']
    let $record-1 := replace($record, "^&quot;|&quot;$", "")
    let $record-2 := replace($record-1, "&quot;&quot;", "&quot;")

    return $record-2
