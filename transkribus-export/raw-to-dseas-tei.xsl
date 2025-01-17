<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:local="local"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="array map xd xs"
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
    
    <xsl:param name="fileName" select="'dummy'"/>
    <xsl:variable name="fileType" select="if (matches($fileName, 'letter')) then 'letter' else 'smallform'"/>
    
    <xsl:param name="schema" select="'../schema/tei_dseas.rng'"/>
    <xsl:param name="schematron" select="'../schema/dseas.sch'"/>
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xsl:template match="/">
        <xsl:call-template name="PIs"/>
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="xml:id" select="$fileName"/>
            <xsl:attribute name="type" select="'dseas-'||$fileType"/>
            <xsl:call-template name="teiHeader"/>
            <text>
                <body>
                    <xsl:apply-templates select="//text/node()"/>
                </body>
            </text>
        </TEI>
    </xsl:template>
    
    <!--Processing instructions-->
    <xsl:template name="PIs">        
        <xsl:processing-instruction name="xml-model">href="{$schema}" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
        <xsl:processing-instruction name="xml-model">href="{$schematron}" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
    </xsl:template>
    
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
                <sourceDesc>
                    <p/>
                </sourceDesc>
            </fileDesc>
        </teiHeader>
    </xsl:template>
    
    <!--Add @break (yes/no) to lb-->
    <xsl:template match="lb">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="break" select="if (matches(preceding::text() => string-join() => normalize-space(),'¬$')) then 'no' else 'yes'"/>
        </xsl:copy>
    </xsl:template>
    
    <!--Unwrap zone divs-->
    <xsl:template match="div[starts-with(@xml:id,'dummy_')]">  
        <!--TODO: Adding pb here?-->
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <!--Transform CONV tag: paragraph-->
    <xsl:template match="CONV[@tag='p']">
        <xsl:element name="{@tag}">
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>
    
    <!--Transform CONV tag: figure/paragraph-->
    <xsl:template match="CONV[@tag='fp']">
        <xsl:element name="figure">
            <xsl:element name="head"/>
            <xsl:element name="p">
                <xsl:apply-templates select="node()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <!--Transform CONV tag: figure-->
    <xsl:template match="CONV[@tag='f']">
        <xsl:element name="figure">
            <xsl:element name="head">
                <xsl:apply-templates select="node()"/>
            </xsl:element>
            <xsl:element name="p"/>
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
    
</xsl:transform>