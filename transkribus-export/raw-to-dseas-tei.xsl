<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:local="local"
  xmlns="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="#all"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  expand-text="true"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jan 16, 2025</xd:p>
      <xd:p><xd:b>Author:</xd:b> cf, pd</xd:p>
      <xd:p></xd:p>
    </xd:desc>
  </xd:doc>
  
  <!--We should only indent whitespace-safely-->
  <xsl:output indent="no"/>
  
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:mode name="combine-hi" on-no-match="shallow-copy"/>
  <xsl:mode name="del-overstrike" on-no-match="shallow-copy"/>
  <xsl:mode on-no-match="shallow-copy" name="wrap-paragraphs"/>
  
  <xsl:import href="raw-to-dseas-reflow-ws.xsl"/>
  
  <xsl:variable name="fileName" select="/TEI/@xml:id" as="xs:string"/>
  
  <xsl:template match="/">
    
    <!-- gather loosely floating contents in pseudo-paragraphs -->
    <xsl:variable name="processed" as="node()*">
      <xsl:apply-templates mode="wrap-paragraphs"/>
    </xsl:variable>
    
    
    <xsl:variable name="processed" as="node()*">
      <xsl:apply-templates select="$processed"/>
    </xsl:variable>
    
    <xsl:variable name="processed" as="node()*">
      <xsl:apply-templates select="$processed" mode="combine-hi"/>
    </xsl:variable>
    
    <xsl:variable name="processed" as="node()*">
      <xsl:apply-templates select="$processed" mode="del-overstrike"/>
    </xsl:variable>
    
    <xsl:variable name="processed" as="node()*">
      <xsl:apply-templates select="$processed" mode="reflow-ws"/>
    </xsl:variable>
    
    <xsl:sequence select="$processed"/>
    
  </xsl:template>
  
  <xsl:template match="TEI">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:base" select="'https://annemarie-schwarzenbach.ch/'||@xml:id||'#'"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@xml:id">
    <xsl:attribute name="xml:id" select="replace(.,$fileName||'_','p')"/>
  </xsl:template>
  
  <!--Add @break (no) to lb-->
  <xsl:template match="lb">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="matches(preceding::text() => string-join() => normalize-space(),'¬$')">
        <xsl:attribute name="break">no</xsl:attribute>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!--Remove hyphenation before lb-->
  <xsl:template match="text()[matches(.,'¬\n?$')]
    [
      following::element()[position()=1 and local-name()='lb'] or
      (following::element()[position()=1 and local-name()='milestone'] and following::element()[position()=2 and local-name()='lb'])
    ]">
    <xsl:value-of select=". => replace('¬', '')"/>
  </xsl:template>  
  
  <!--Transform CONV tag: paragraph-->
  <xsl:template match="CONV[@tag='p']">
    <xsl:element name="{@tag}">
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>
  
  <!--Transform CONV tag: pseudo paragraph-->
  <xsl:template match="CONV[@tag='pseudo-p']">
    <p local:warning="FML-generated-to-avoid-structural-problems">
      <xsl:apply-templates select="node()"/>
    </p>
  </xsl:template>
  
  <xsl:template match="CONV[@tag='pseudo-p'][not(normalize-space() or element() or comment())]"/>
  
  <!--Transform CONV tag: figure/paragraph-->
  <xsl:template match="CONV[@tag='fp']">
    <p local:warning="FML-figure-paragraph">
      <xsl:apply-templates select="node()"/>
    </p>
  </xsl:template>

  <!--Transform CONV tag: figure-->
  <xsl:template match="CONV[@tag='f']">
    <figure>
      <head>
        <xsl:apply-templates select="node()"/>
      </head>
    </figure>
  </xsl:template>
  
  <!--Transform CONV tag: g-->
  <xsl:template match="CONV[@tag='g']">
    <xsl:element name="hi">
      <xsl:attribute name="rendition" select="'#g'"/>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>
  
  <!--Transform PAGE tag: hi (i.e. bold, italic, strikethrough, underlined, subscript, superscript)-->
  <xsl:template match="PAGE[matches(@tag,'bold|italic|strikethrough|underlined|subscript|superscript')]">
    <xsl:element name="hi">
      <xsl:attribute name="rendition" select="
        if (@tag='bold') then '#b'
        else if (@tag='italic') then '#i'
        else if (@tag='strikethrough') then '#lt'
        else if (@tag='underlined') then '#u'
        else if (@tag='subscript') then '#sub'
        else if (@tag='superscript') then '#sup'
        else @tag
        "/>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>
  
  
  <!-- [mode] wrap-paragraphs 
              gather loosely floating content
       ======================================== -->  
  
  <xsl:template match="body" mode="wrap-paragraphs">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:for-each-group select="node()" group-starting-with="CONV[@tag='p' or @tag='fp' or @tag='f'] | milestone | pb | comment()">
        <xsl:for-each-group select="current-group()" group-ending-with="self::CONV | self::milestone | self::pb | self::comment()">
          <xsl:choose>
            <xsl:when test="current-group()[self::CONV[@tag='p' or @tag='fp' or @tag='f'] | self::milestone | self::pb | self::comment()]">
              <xsl:copy-of select="self::CONV | self::milestone | self::pb | self::comment()"/>
            </xsl:when>
            <xsl:otherwise>
              <CONV tag="pseudo-p">
                <xsl:sequence select="current-group()"/>
              </CONV>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
    
  <!-- [mode] combine-hi 
              merge line-spanning highlights
       ======================================== -->     
  
  <xsl:template match="*[hi]" mode="combine-hi">
    <xsl:copy>
      <xsl:sequence select="@*" />
      <xsl:for-each-group select="node()"
        group-starting-with="hi[
        @rendition != preceding-sibling::hi[1]/@rendition
        or not(preceding-sibling::hi)
        or normalize-space(string-join(preceding-sibling::hi[1]/following-sibling::node() intersect preceding-sibling::node())) != ''
        ]">
        <xsl:choose>
          <xsl:when test="not(current-group()[self::hi])">
            <xsl:sequence select="current-group()" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="lastHi" select="index-of(current-group(), current-group()[self::hi][last()])"/>
            <hi rendition="{current-group()[1]/@rendition}" xmlns="http://www.tei-c.org/ns/1.0">
              <xsl:apply-templates select="current-group()[position() le $lastHi]" mode="do-combine-hi" />
            </hi>
            <xsl:sequence select="current-group()[position() gt $lastHi]" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="hi" mode="do-combine-hi">
    <xsl:apply-templates mode="combine-hi"/>
  </xsl:template>
  
  <xsl:template match="*:lb" mode="do-combine-hi">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- [mode] del-overstrike 
              transform <hi rendition="#lt"/> to <del rend="overstrike"/>
       ======================================== -->  
  
  <xsl:template match="hi[matches(@rendition,'#lt')]" mode="del-overstrike">
    <xsl:element name="del">
      <xsl:attribute name="rend" select="'overstrike'"/>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>
  
</xsl:transform>
