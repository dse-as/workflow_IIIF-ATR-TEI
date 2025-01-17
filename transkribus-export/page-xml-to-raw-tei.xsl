<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:local="local"
  xmlns="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="array local map xd xs"
  xpath-default-namespace="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
  expand-text="true"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Nov 27, 2024</xd:p>
      <xd:p><xd:b>Author:</xd:b> pd</xd:p>
      <xd:p></xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output indent="true"/>
  
  <xsl:param name="fileName" select="(//Page)[1]/@imageFilename => replace('^(\w+_\d{4}).*$','$1')"/>
  
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:mode name="lines-break-before-lb" on-no-match="shallow-copy"/>
  <xsl:mode name="lines-page-tags" on-no-match="shallow-copy"/>
  <xsl:mode name="rm-tmp-id" on-no-match="shallow-copy"/>
  <xsl:mode name="lines-conventional-tags" on-no-match="shallow-copy"/>
  <xsl:mode name="lines-conventional-tags-comments" on-no-match="shallow-copy"/>
  <xsl:mode name="move-lb" on-no-match="shallow-copy"/>
  
  <xsl:variable name="PAGE-tag-info" as="map(*)">
    <xsl:sequence select="//TextLine[contains(@custom,'textStyle')] ! 
      map:entry(@id||'-'||generate-id(@id), 
      for-each(@custom => substring-after('textStyle'), 
      function($a) { local:parse-PAGE-tag-syntax($a)})
      ) => map:merge()"/>
  </xsl:variable>
  
  
  <xsl:template match="/">
    
    <xsl:comment>
      debug page-tag-map:
    
      <xsl:sequence select="$PAGE-tag-info => serialize(map {'method': 'json'})"/>
    </xsl:comment>
    
    <xsl:result-document href="{$fileName}_raw.xml" method="xml" encoding="UTF-8">
      <text>
        <xsl:apply-templates select="//TextRegion"/>
      </text>
    </xsl:result-document>
  
  </xsl:template>
  
  <xsl:template match="TextRegion">
    <milestone unit="textregion" xml:id="{$fileName}_{@id}"/>
    <!-- raw lines -->
    <xsl:variable name="lines">
      <xsl:apply-templates select=".//TextLine" mode="lines-raw"/>
    </xsl:variable>
    <!-- TODO for GH action: xsl:result-document -->
    
    <!-- PAGE tags -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="lines-page-tags"/>
    </xsl:variable>
    <!-- TODO for GH action: xsl:result-document -->

    <!-- rm @tmp-id -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="rm-tmp-id"/>
    </xsl:variable>

    <!-- CONV tags -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="lines-conventional-tags"/>
    </xsl:variable>
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="lines-conventional-tags-comments"/>
    </xsl:variable>
    <!-- TODO for GH action: xsl:result-document -->
    
    <!-- move lb within CONV tags -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="move-lb"/>
    </xsl:variable>
    <!-- TODO for GH action: xsl:result-document -->
    
    <!-- break before lb -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="lines-break-before-lb"/>
    </xsl:variable>
    <!-- TODO for GH action: xsl:result-document -->
    
    <xsl:sequence select="$lines"/>
    <!-- TODO for GH action: xsl:result-document -->

  </xsl:template>
  
  <!-- raw lines: raw unicode content with interspersed lb elements -->
  <xsl:template match="TextLine" mode="lines-raw">
    <!-- @tmp-id is used as a temporary unique line identifier (the Transkribus/PAGE line IDs are not always unique per document) -->
    <lb xml:id="{$fileName}_{@id}" tmp-id="{@id||'-'||generate-id(@id)}"/>
    <xsl:apply-templates select=".//TextEquiv/Unicode/node()"/>
  </xsl:template>
  
  <!-- PAGE tag milestones -->
  <!-- strategy: to avoid debugging hell due to improperly nested tags we only strew in milestones, based on the Transkribus tag offsets
                 this will allow to generate intermediary outputs that help to track down problems
  -->
  <xsl:template match="text()" mode="lines-page-tags">
    <xsl:variable name="lineId" select="preceding-sibling::*:lb[1]/@tmp-id"/>
    <xsl:variable name="lineTags" select="map:get($PAGE-tag-info,$lineId)"/>
    <xsl:variable name="line" select="."/>
    
    <!-- XSLT 4.0 will offer xsl:iterate with array/map selector; the following works around this by position-based calls of array:get() -->
    <xsl:choose>
      <xsl:when test="exists($lineTags)">
        <xsl:iterate select="1 to array:size($lineTags)">
          <xsl:param name="line" select="$line"/>
          <xsl:param name="pos" select="1"/>
          <xsl:on-completion select="$line"/>
          <!-- as we are printing additional characters to the string, the array is reversed to process the string from the back to the front -->
          <xsl:variable name="currentMap" select="$lineTags => array:reverse() => array:get($pos)" as="map(*)"/>
          <xsl:variable name="regex" select="'(.{'||$currentMap?offset||'})(.{'||$currentMap?length||'})(.*)'"/>
          <xsl:variable name="posIncr" select="$pos + 1"/>
          <!--<xsl:comment>POS {$pos}</xsl:comment>
          <xsl:comment>REGEX {$regex}</xsl:comment>
          <xsl:comment>LINE {$line}</xsl:comment>-->
          <xsl:variable name="processedLine">
            <xsl:analyze-string select="$line" regex="{$regex}">
              <xsl:matching-substring>
                <xsl:sequence select="regex-group(1)||'┋PAGE-tag:'||$currentMap?tag||'┊'||regex-group(2)||'┊PAGE-tag:'||$currentMap?tag||'┋'||regex-group(3)"/>
              </xsl:matching-substring>
              <xsl:non-matching-substring>{$line}</xsl:non-matching-substring>
            </xsl:analyze-string>
          </xsl:variable>
          <xsl:next-iteration>
            <xsl:with-param name="line" select="$processedLine"/>
            <xsl:with-param name="pos" select="$posIncr"/>
          </xsl:next-iteration>
        </xsl:iterate>
      </xsl:when>
      <xsl:otherwise>{$line}</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- rm @tmp-id -->
  <xsl:template match="Q{http://www.tei-c.org/ns/1.0}lb" mode="rm-tmp-id">
    <xsl:copy>
      <xsl:copy-of select="@* except @tmp-id">
    </xsl:copy>
  </xsl:template>

  <!-- pre-process conventionalised tags -->
  <xsl:template match="text()" mode="lines-conventional-tags">
    <xsl:sequence select=". =>
      replace('\\:(fp)\\','┊CONV-tag:$1┋') => replace('\\(fp)\\','┋CONV-tag:$1┊') =>
      replace('\\:(f)\\','┊CONV-tag:$1┋') => replace('\\(f)\\','┋CONV-tag:$1┊') =>
      replace('\\:(p)\\','┊CONV-tag:$1┋') => replace('\\(p)\\','┋CONV-tag:$1┊')
      "/>
  </xsl:template>
  
  <xsl:template match="text()" mode="lines-conventional-tags-comments">
    <xsl:analyze-string select="." regex="\\(del|fml)\\">
      <xsl:matching-substring>
        <xsl:comment>FML: this needs attention (was tagged as "{regex-group(1)}" in Transkribus)</xsl:comment>
      </xsl:matching-substring>
      <xsl:non-matching-substring>{.}</xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  
  <!-- move lb within CONV tags -->
  <xsl:template match="text()[starts-with(.,'┋CONV-tag:')]" mode="move-lb">
    <xsl:variable name="head" select="replace(.,'^(┋CONV-tag:\w*┊).*','$1')"/>
    <xsl:variable name="tail" select="substring-after(.,'┊')"/>
    <!--<xsl:comment>head: {$head}</xsl:comment>
    <xsl:comment>tail: {$tail}</xsl:comment>-->
    <xsl:sequence select="$head"/>
    <xsl:copy-of select="preceding-sibling::*[1]"/>
    <xsl:sequence select="$tail"/>
  </xsl:template>
  <xsl:template match="Q{http://www.tei-c.org/ns/1.0}lb[following-sibling::node()[1][self::text()][starts-with(.,'┋CONV-tag:')]]" mode="move-lb"/>
  
  <!-- break before lb -->
  <xsl:template match="text()[following-sibling::*[1]/self::Q{http://www.tei-c.org/ns/1.0}lb]" mode="lines-break-before-lb">
    <xsl:sequence select=".||'&#xA;'"/>
  </xsl:template>

  <!-- local functions
       =============== -->
  
  <xsl:function name="local:parse-PAGE-tag-syntax" as="array(*)">
    <xsl:param name="input"/>
    <xsl:variable name="maps" as="map(*)*">
      <xsl:for-each select="tokenize($input,'\}')[matches(.,'\w')]">
        <xsl:map>
          <xsl:map-entry key="'tag'" select="(. => tokenize(';'))[normalize-space()][last()] => substring-before(':')"/>
          <xsl:map-entry key="'offset'" select=". => substring-after('offset:') => substring-before(';')"/>
          <xsl:map-entry key="'length'" select=". => substring-after('length:') => substring-before(';')"/>
        </xsl:map>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="array { $maps }"/>
  </xsl:function>
  
</xsl:transform>