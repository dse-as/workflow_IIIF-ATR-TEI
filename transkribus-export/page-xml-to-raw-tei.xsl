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

  <xsl:param name="debug" static="true" as="xs:boolean" select="false()"/>
  
  <xsl:param name="fileName" select="if (matches((//Page)[1]/@imageFilename,'letter_0249')) then 'letter_0250' else (//Page)[1]/@imageFilename => replace('^(\w+_\d{4}).*$','$1')"/>
  <xsl:variable name="fileType" select="if (matches($fileName, 'letter')) then 'letter' else 'smallform'"/>
  <xsl:variable name="iiif-manifest" select="json-doc('https://iiif.annemarie-schwarzenbach.ch/presentation/'||$fileName||'.json')"/>
  
  <!-- TODO: Change path to "../schema/tei_dseas.rng" when the schema files have been moved to the documents -->
  <xsl:param name="schema" select="'https://cdn.jsdelivr.net/gh/dse-as/oxygen-framework@latest/schema/tei_dseas.rng'"/>
  <xsl:param name="schematron" select="'https://cdn.jsdelivr.net/gh/dse-as/oxygen-framework@latest/schema/dseas.sch'"/>

  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:mode name="coords" on-no-match="shallow-skip"/>
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

    <xsl:comment use-when="$debug">
      debug page-tag-map:
    
      <xsl:sequence select="$PAGE-tag-info => serialize(map {'method': 'json'})"/>
      
      debug iiif manifest:
      <xsl:variable name="ifn" select="'letter_0004_001'"/>
      <xsl:sequence select="$iiif-manifest?items?*[.?label?en?*=$ifn]?items?*?items?*?body?id => serialize(map {'method': 'json'})"/>
    </xsl:comment>

    <xsl:result-document href="data/0-transkribus-PAGE/{$fileName}_page.xml" method="xml" encoding="UTF-8">
      <xsl:copy-of select="*"/>
    </xsl:result-document>
    
    <xsl:result-document href="data/1-raw-TEI/{$fileName}_raw.xml" method="xml" encoding="UTF-8">
      <xsl:call-template name="build-raw-tei"/>
    </xsl:result-document>
    
    <xsl:result-document href="commit-message.txt" method="text" encoding="UTF-8">
      <xsl:text>Transkribus export: {$fileName}&#xA;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
      <xsl:text>* _generated/0-transkribus-PAGE/{$fileName}_page.xml&#xA;</xsl:text>
      <xsl:text>* _generated/1-raw-TEI/{$fileName}_raw.xml&#xA;</xsl:text>
      <xsl:text>* _generated/2-base-TEI/{$fileName}.xml&#xA;</xsl:text>
    </xsl:result-document>
    
    <xsl:result-document href="issue-reply-post-transform.txt" method="text" encoding="UTF-8">
      <xsl:text>Transkribus export: {$fileName}&#xA;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
      <xsl:text>**Exported:**&#xA;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
      <xsl:text>* [`_generated/0-transkribus-PAGE/{$fileName}_page.xml`](../tree/main/_generated/0-transkribus-PAGE/{$fileName}_page.xml)&#xA;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
      <xsl:text>**Generated:**&#xA;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
      <xsl:text>* [`_generated/1-raw-TEI/{$fileName}_raw.xml`](https://github.com/dse-as/workflow_IIIF-ATR-TEI/tree/main/tree/main/_generated/1-raw-TEI/{$fileName}_raw.xml)&#xA;</xsl:text>
      <xsl:text>* [`_generated/2-base-TEI/{$fileName}.xml`](https://github.com/dse-as/workflow_IIIF-ATR-TEI/tree/main/_generated/2-base-TEI/{$fileName}.xml)&#xA;</xsl:text>
    </xsl:result-document>
    
  </xsl:template>
  
  <xsl:template name="build-raw-tei">
    <xsl:call-template name="PIs"/>
    <TEI xml:id="{$fileName}" type="{'dseas-'||$fileType}">
      <xsl:call-template name="teiHeader"/>
      <xsl:call-template name="facsimile"/>
      <text>
        <body>
          <div type="{$fileType}">
            <xsl:apply-templates select="//Page"/>
          </div>
        </body>
      </text>
      <xsl:comment use-when="$debug">Generated on {current-dateTime()} by https://github.dev/dse-as/workflow_IIIF-ATR-TEI using {system-property('xsl:product-name')} {system-property('xsl:product-version')} from {system-property('xsl:vendor')}.</xsl:comment>
    </TEI>
  </xsl:template>
  
  <!--Processing instructions-->
  <xsl:template name="PIs">        
    <xsl:processing-instruction name="xml-model">href="{$schema}" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
    <xsl:processing-instruction name="xml-model">href="{$schematron}" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
  </xsl:template>
  
  <!-- unnamed mode -->
  
  <!--teiHeader-->
  <xsl:template name="teiHeader">
    <teiHeader>
      <fileDesc>
        <titleStmt>
          <title>{$fileName}</title>
        </titleStmt>
        <publicationStmt>
          <p/>
        </publicationStmt>
        <notesStmt>
          <note type="global_comment">
            <p/>
          </note>
        </notesStmt>
        <sourceDesc>
          <xsl:choose>
            <xsl:when test="$fileType = 'letter'">
              <msDesc>
                <msIdentifier>
                  <repository/>
                  <collection/>
                  <idno/>
                </msIdentifier>
              </msDesc>
            </xsl:when>
            <xsl:when test="$fileType = 'smallform'">
              <bibl corresp="{$fileName}">
                <persName key="person_0082" type="author">Schwarzenbach, Annemarie (1908-1942)</persName>
                <bibl>
                  <title level="j"/>
                  <date/>
                  <biblScope/>
                </bibl>
              </bibl>
            </xsl:when>
            <xsl:otherwise>
              <p/>
            </xsl:otherwise>
          </xsl:choose>
          <listBibl type="related">
            <listBibl type="online">
              <bibl/>
            </listBibl>
          </listBibl>
        </sourceDesc>
      </fileDesc>
      <profileDesc>
        <xsl:if test="$fileType = 'letter'">
          <correspDesc>
            <correspAction type="sent">
              <persName/>
              <date/>
              <placeName/>
            </correspAction>
            <correspAction type="received">
              <persName/>
              <placeName/>
            </correspAction>
          </correspDesc>
        </xsl:if>
        <langUsage>
          <language/>
        </langUsage>
        <textClass>
          <keywords ana="keywords">
            <list>
              <item/>
            </list>
          </keywords>
          <keywords ana="travels">
            <list>
              <item/>
            </list>
          </keywords>
        </textClass>
      </profileDesc>
    </teiHeader>
  </xsl:template>
  
  <xsl:template name="facsimile">
    <xsl:result-document href="data/2-base-TEI/{$fileName}_facs.xml" method="xml" encoding="UTF-8">
      <facsimile xml:id="{$fileName}_facs">
        <xsl:apply-templates select="//Page" mode="coords"/>
      </facsimile>
    </xsl:result-document>
    <xsl:element name="xi:include" namespace="http://www.w3.org/2001/XInclude">
      <xsl:attribute name="href" select="$fileName||'_facs.xml'"/>
      <xsl:element name="xi:fallback" namespace="http://www.w3.org/2001/XInclude"/>
      <xsl:comment>Inclusion path will be adjusted later.</xsl:comment>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="Page">
    <xsl:variable name="ifn" select="@imageFilename => substring-before('.')"/>
    <!--IIIF Image or Presentation URL?-->
    <xsl:variable name="pos" select="position()" as="xs:integer"/>
    <pb xml:id="{local:page-id($fileName,$pos)}" facs="{local:get-facs-url($ifn)}"/>
    <xsl:apply-templates select="TextRegion">
      <xsl:with-param name="pos" select="$pos" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="TextRegion">
    <xsl:param name="pos" as="xs:integer" tunnel="yes"/>
    <milestone unit="textregion" xml:id="{local:page-id($fileName,$pos)}_{@id}"/>
    <!-- raw lines -->
    <xsl:variable name="lines">
      <xsl:apply-templates select=".//TextLine" mode="lines-raw"/>
    </xsl:variable>
    <xsl:result-document href="data/1-raw-TEI/debug-lines/{$fileName}_0_lines-raw_{local:page-id($fileName,$pos)}_{@id}.xml" method="xml" encoding="UTF-8" use-when="$debug">
        <xsl:sequence select="$lines"/>
    </xsl:result-document>
    
    <!-- PAGE tags -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="lines-page-tags"/>
    </xsl:variable>
    <xsl:result-document href="data/1-raw-TEI/debug-lines/{$fileName}_1_lines-page-tags_{local:page-id($fileName,$pos)}_{@id}.xml" method="xml" encoding="UTF-8" use-when="$debug">
        <xsl:sequence select="$lines"/>
    </xsl:result-document>
    
    <!-- rm @tmp-id -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="rm-tmp-id"/>
    </xsl:variable>
    <xsl:result-document href="data/1-raw-TEI/debug-lines/{$fileName}_2_rm-tmp-id_{local:page-id($fileName,$pos)}_{@id}.xml" method="xml" encoding="UTF-8" use-when="$debug">
        <xsl:sequence select="$lines"/>
    </xsl:result-document>

    <!-- CONV tags -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="lines-conventional-tags"/>
    </xsl:variable>
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="lines-conventional-tags-comments"/>
    </xsl:variable>
    <xsl:result-document href="data/1-raw-TEI/debug-lines/{$fileName}_3_lines-conventional-tags-comments_{local:page-id($fileName,$pos)}_{@id}.xml" method="xml" encoding="UTF-8" use-when="$debug">
        <xsl:sequence select="$lines"/>
    </xsl:result-document>
    
    <!-- move lb within CONV tags -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="move-lb"/>
    </xsl:variable>
    <xsl:result-document href="data/1-raw-TEI/debug-lines/{$fileName}_4_move-lb_{local:page-id($fileName,$pos)}_{@id}.xml" method="xml" encoding="UTF-8" use-when="$debug">
        <xsl:sequence select="$lines"/>
    </xsl:result-document>
    
    <!-- break before lb -->
    <xsl:variable name="lines">
      <xsl:apply-templates select="$lines" mode="lines-break-before-lb"/>
    </xsl:variable>
    <xsl:result-document href="data/1-raw-TEI/debug-lines/{$fileName}_5_lines-break-before-lb_{local:page-id($fileName,$pos)}_{@id}.xml" method="xml" encoding="UTF-8" use-when="$debug">
        <xsl:sequence select="$lines"/>
    </xsl:result-document>
    
    <xsl:sequence select="$lines"/>
    
  </xsl:template>
  

  <!-- ========================================
       | named modes                          |
       ======================================== -->
  
  <!-- [mode] raw lines: raw unicode content 
              with interspersed lb elements
       ======================================== -->
  <!--  -->
  <xsl:template match="TextLine" mode="lines-raw">
    <xsl:param name="pos" as="xs:integer" tunnel="yes"/>
    <!-- @tmp-id is used as a temporary unique line identifier (the Transkribus/PAGE line IDs are not always unique per document) -->
    <lb xml:id="{local:page-id($fileName,$pos)}_{@id}" tmp-id="{@id||'-'||generate-id(@id)}"/>
    <xsl:apply-templates select=".//TextEquiv/Unicode/node()"/>
  </xsl:template>
  
  <!-- [mode] PAGE tag milestones
       ======================================== -->
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
  
  <!-- [mode] coords
       ======================================== -->
  <xsl:template match="Page" mode="coords">
    <surface xml:id="{local:page-id($fileName,position())}_facs" ulx="0" uly="0" lrx="{@imageWidth}" lry="{@imageHeight}">
      <graphic url="{local:get-facs-url(@imageFilename=>substring-before('.'))}" width="{@imageWidth}" height="{@imageHeight}"/>
      <xsl:variable name="pos" as="xs:integer" select="position()"/>
      <xsl:apply-templates select="TextRegion" mode="coords">
        <xsl:with-param name="pageNr" select="$pos" tunnel="yes"/>
      </xsl:apply-templates>
    </surface>
  </xsl:template>
  
  <xsl:template match="TextRegion" mode="coords">
    <xsl:param name="pageNr" as="xs:integer" tunnel="yes"/>
    <zone xml:id="{local:page-id($fileName,$pageNr)}_{@id}" points="{Coords/@points}" rendition="TextRegion">
      <xsl:apply-templates select="TextLine" mode="coords"/>
    </zone>
  </xsl:template>
  
  <xsl:template match="TextLine" mode="coords">
    <xsl:param name="pageNr" as="xs:integer" tunnel="yes"/>
    <zone xml:id="{local:page-id($fileName,$pageNr)}_{@id}" points="{Coords/@points}" rendition="TextLine"/>
  </xsl:template>
  
  <!-- [mode] rm @tmp-id
       ======================================== -->  
  <xsl:template match="Q{http://www.tei-c.org/ns/1.0}lb" mode="rm-tmp-id">
    <xsl:copy>
      <xsl:copy-of select="@* except @tmp-id"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- [mode] pre-process conventionalised tags
       ======================================== -->  
  <xsl:template match="text()" mode="lines-conventional-tags">
    <xsl:sequence select=". =>
      replace('\\:(fp)\\','┊CONV-tag:$1┋') => replace('\\(fp)\\','┋CONV-tag:$1┊') =>
      replace('\\:(f)\\','┊CONV-tag:$1┋') => replace('\\(f)\\','┋CONV-tag:$1┊') =>
      replace('\\:(p)\\','┊CONV-tag:$1┋') => replace('\\(p)\\','┋CONV-tag:$1┊') =>
      replace('\\:(g)\\','┊CONV-tag:$1┋') => replace('\\(g)\\','┋CONV-tag:$1┊')
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
  
  <!-- [mode] move lb within CONV tags
       ======================================== -->
  <xsl:template match="text()[starts-with(.,'┋CONV-tag:')]" mode="move-lb">
    <xsl:variable name="head" select="replace(.,'^(┋CONV-tag:\w*?┊).*','$1')"/>
    <xsl:variable name="tail" select="substring-after(.,'┊')"/>
    <!--<xsl:comment>head: {$head}</xsl:comment>
    <xsl:comment>tail: {$tail}</xsl:comment>-->
    <xsl:sequence select="$head"/>
    <xsl:copy-of select="preceding-sibling::*[1]"/>
    <xsl:sequence select="$tail"/>
  </xsl:template>
  <xsl:template match="Q{http://www.tei-c.org/ns/1.0}lb[following-sibling::node()[1][self::text()][starts-with(.,'┋CONV-tag:')]]" mode="move-lb"/>
  
  <!-- [mode] break before lb
       ======================================== -->  
  <xsl:template match="text()[following-sibling::*[1]/self::Q{http://www.tei-c.org/ns/1.0}lb]" mode="lines-break-before-lb">
    <xsl:sequence select=".||'&#xA;'"/>
  </xsl:template>
  
  <!-- ========================================
       | local functions                      |
       ======================================== -->
  
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
  
  <xsl:function name="local:get-facs-url" as="xs:string">
    <xsl:param name="imageFilename" as="xs:string"/>
    <xsl:sequence select="$iiif-manifest?items?*[.?label?en?*=$imageFilename]?items?*?items?*?body?id"/>
  </xsl:function>
  
  <xsl:function name="local:page-id" as="xs:string">
    <xsl:param name="fileName" as="xs:string"/>
    <xsl:param name="pos" as="xs:integer"/>
    <xsl:sequence select="$fileName||'_'||$pos=>format-number('000')"/>
  </xsl:function>
  
</xsl:transform>
