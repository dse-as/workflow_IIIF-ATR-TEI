<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xpath31"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    
    <ns prefix="PAGE" uri="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"/>
        
    <!-- image filename according to convention -->
    <pattern id="pa_general-check-image-filename">
        <rule id="ru_general-check-image-filename" context="@imageFilename">
            <assert test="matches(.,'^\w+_\d{4}_\d{3}\.\w+$')">Attribute imageFilename need to follow the convention.</assert>
            <!--<report role="warn" test="matches(.,'dsl_dev')">The 'dsl_dev' collection should be changed to 'schwarzenbach'.</report>-->
        </rule>
    </pattern>

    <!-- special syntax: agreed-upon markers in Transkribus -->

    <!-- invalid markers (e.g. forward instead of backward slash) -->
    <pattern id="pa_special-syntax-test-2">
        <rule context="PAGE:Unicode" id="ru_special-syntax-test-2">
            <assert test="not(matches(text(),'/:?p/'))">**Symbols `/p/` and `/:p/` are not allowed**&#xA;  *at:* "<value-of select="text() => replace('(/:?p/)','`$1`')"/>".</assert>
        </rule>
    </pattern>

    <!-- marker `\p\`, `\:p\` (beginning and end of paragraph)
     strategy: split by paragraph and look for paragraph ends (by tokenization); there should be two tokens; any other number of tokens is reported -->
    <pattern id="pa_special-syntax-test-1">
        <rule context="validation-wrapper" id="ru_special-syntax-test-1">
            <assert test="
            every $token in (//PAGE:Unicode/text() => string-join(' ') 
            => tokenize('\\p\\'))[position() gt 1] satisfies
            tokenize($token,'\\:p\\') => count() = 2
            ">**Paragraphs must contain a starting and ending symbol**&#xA;  <value-of select="
            for $token in (//PAGE:Unicode/text() => string-join(' ') 
            => tokenize('\\p\\'))[position() gt 1] 
            return let $counterpart := tokenize($token,'\\:p\\') 
            => count() return $counterpart[not(.=2)]
            !('*Not 2 tokens but '||.||' tokens at:* &quot;'||$token => replace('(\\:?p\\)','`$1`')||'&quot;.')"/></assert>

        </rule>
    </pattern>
            

    <!-- Showcasing that we support checks on processing instructions. -->
    <!--<pattern id="pa_processing-instructions-test">
    <rule id="ru_processing-instructions-test" context="processing-instruction('xml-model')">
        <assert test="contains(.,'foobar')">
        XML model processing instruction does not include foobar.
        </assert>
    </rule>
    </pattern>-->

    <!-- Showcasing that we support checks on comments. -->
    <!--<pattern id="pa_comments-test">
    <rule id="ru_comments-test" context="comment()">
        <assert test="starts-with(., ' Comment: ')">
        This comment does not start with "Comment: ".
        </assert>
    </rule>
    </pattern>-->
  
</schema>