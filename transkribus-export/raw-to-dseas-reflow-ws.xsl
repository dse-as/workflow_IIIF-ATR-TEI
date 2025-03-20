<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <!--
        Based on NISO STS XML whitespace normalizer,
        https://github.com/usnistgov/oscal-xproc3/blob/main/projects/FM6-22-import/src/sts-reflow-ws.xsl
    -->
    
    <xsl:mode name="reflow-ws" on-no-match="shallow-copy"/>
    
    <xsl:output indent="no"/>
    
    <xsl:param name="indent-spaces" select="3"/>
    
    <xsl:variable name="indent-ws" select="(1 to xs:integer($indent-spaces)) ! ' '"/>
    
    <xsl:template match="/" mode="reflow-ws">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template mode="reflow-ws" match="*[@xml:space='preserve']">
        <xsl:sequence select="string(.)"/>
    </xsl:template>
    
    <xsl:template mode="reflow-ws" match="text()">
        <xsl:sequence select="replace(string(.),'\s+',' ')"/>
    </xsl:template>
    
    <xsl:template  mode="reflow-ws" match="/comment() | /processing-instruction()">
        <xsl:text>&#xA;</xsl:text>
        <xsl:next-match/>
    </xsl:template>
    
    <!-- Block elements (with and without mixed content) -->
    <xsl:template mode="reflow-ws" match="
        *:TEI | 
        *:teiHeader | 
        *:fileDesc | 
        *:titleStmt | 
        *:title |
        *:publicationStmt | 
        *:notesStmt | 
        *:note |
        *:sourceDesc |
        *:msDesc |
        *:msIdentifier |
        *:repository |
        *:collection |
        *:idno |
        *:altIdentifier |
        *:profileDesc |
        *:textClass |
        *:correspDesc |
        *:correspAction |
        *:persName |
        *:placeName |
        *:date |
        *:keywords |
        *:langUsage |
        *:language |
        *:list |
        *:item |
        *:text | 
        *:body | 
        *:div | 
        *:head | 
        *:figure | 
        *:p"
        expand-text="true">
        <xsl:variable name="me" select="."/>
        <!--LF before start tag if no one has closed before us (giving an LF) -->
        <xsl:text>{ (: conditional LF :) '&#xA;'[$me/preceding-sibling::* => empty()] }</xsl:text>
        <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="reflow-ws"/>
            <!-- conditionally indent before the end tag -->
            <xsl:apply-templates select="." mode="tag-indent"/>
        </xsl:copy>
        <!--LF after end tag-->
        <xsl:text>&#xA;</xsl:text>
    </xsl:template>
    
    <!-- will match any element not element-only -->
    <xsl:template match="*" mode="tag-indent"/>
    
    <!-- Block elements with no mixed content (element-only) -->
    <xsl:template
        match="
        *:TEI | 
        *:teiHeader |
        *:fileDesc | 
        *:titleStmt | 
        *:publicationStmt | 
        *:notesStmt | 
        *:note |
        *:sourceDesc |
        *:msDesc |
        *:msIdentifier |
        *:altIdentifier |
        *:profileDesc |
        *:textClass |
        *:correspDesc |
        *:correspAction |
        *:keywords |
        *:langUsage |
        *:list |
        *:text | 
        *:body | 
        *:figure"
        mode="tag-indent"  expand-text="true">
        <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
    </xsl:template>
    
    <!-- Milestones -->
    <xsl:template mode="reflow-ws" match="*:lb | *:pb | *:milestone" expand-text="true">
        <xsl:variable name="me" select="."/>
        <!--LF before start tag if no one has closed before us (giving an LF) -->
        <xsl:text>{ (: conditional LF :) '&#xA;' }</xsl:text>
        <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="reflow-ws"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>