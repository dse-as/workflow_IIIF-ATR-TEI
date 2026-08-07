<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="local"
    exclude-result-prefixes="xs local"
    version="3.0">

    <!--
        Reflow and serialize TEI-like XML.

        Inspired by NISO STS XML whitespace normalizer,
        https://github.com/usnistgov/oscal-xproc3/blob/main/projects/FM6-22-import/src/sts-reflow-ws.xsl
    -->

    <xsl:mode name="reflow-ws" on-no-match="shallow-copy"/>

    <xsl:output indent="no"/>

    <xsl:param name="indent-spaces" as="xs:integer" select="3"/>

    <xsl:variable name="validated-indent-spaces" as="xs:integer"
        select="
            if ($indent-spaces ge 0)
            then $indent-spaces
            else error(xs:QName('INVALID-INDENT-SPACES'),
                'Parameter indent-spaces must be a non-negative integer.')"/>

    <xsl:variable name="indent-ws" as="xs:string*"
        select="(1 to $validated-indent-spaces) ! ' '"/>

    <!--
        Elements put on their own indented line; covers everything the DSE-AS
        pipeline emits. Kept inline: hi, del, rs, PAGE.
    -->
    <xsl:variable name="block-element-names" as="xs:string+"
        select="
            ((: teiHeader :)
            'TEI', 'teiHeader', 'fileDesc', 'titleStmt', 'title',
            'publicationStmt', 'notesStmt', 'note', 'sourceDesc',
            'msDesc', 'msIdentifier', 'repository', 'collection',
            'idno', 'altIdentifier', 'profileDesc', 'textClass',
            'correspDesc', 'correspAction', 'persName', 'placeName',
            'date', 'biblScope', 'keywords', 'langUsage', 'language',
            'list', 'listBibl', 'item', 'bibl', 'respStmt', 'resp',
            'name', 'publisher', 'availability', 'licence',
            (: text :)
            'text', 'body', 'div', 'head', 'figure', 'p',
            (: facsimile :)
            'facsimile', 'surface', 'zone', 'graphic',
            (: XInclude :)
            'include', 'fallback')"/>

    <!-- Start a line but do not end one: content follows on the same line. -->
    <xsl:variable name="milestone-element-names" as="xs:string+"
        select="('lb', 'pb', 'milestone')"/>

    <xsl:function name="local:is-block-element" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence
            select="$node instance of element() and local-name($node) = $block-element-names"/>
    </xsl:function>

    <xsl:function name="local:previous-significant-sibling" as="node()?">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence
            select="$node/preceding-sibling::node()[not(self::text()[normalize-space(.) = ''])][1]"/>
    </xsl:function>

    <xsl:function name="local:next-significant-sibling" as="node()?">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence
            select="$node/following-sibling::node()[not(self::text()[normalize-space(.) = ''])][1]"/>
    </xsl:function>

    <xsl:function name="local:last-significant-child" as="node()?">
        <xsl:param name="node" as="element()"/>
        <xsl:sequence
            select="$node/node()[not(self::text()[normalize-space(.) = ''])][last()]"/>
    </xsl:function>

    <xsl:function name="local:node-ends-with-lf" as="xs:boolean">
        <xsl:param name="node" as="node()?"/>
        <xsl:sequence select="
            if (empty($node)) then false()
            else if ($node instance of comment()) then true()
            else if ($node instance of element()) then local:is-block-element($node)
            else false()
            "/>
    </xsl:function>

    <xsl:function name="local:needs-leading-lf" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:variable name="previous" select="local:previous-significant-sibling($node)"/>
        <xsl:sequence select="empty($previous) or not(local:node-ends-with-lf($previous))"/>
    </xsl:function>

    <xsl:function name="local:starts-own-line" as="xs:boolean">
        <xsl:param name="node" as="node()?"/>
        <xsl:sequence select="
            if (empty($node)) then false()
            else if ($node instance of comment()) then true()
            else if ($node instance of element())
                then local:is-block-element($node)
                     or local-name($node) = $milestone-element-names
            else false()
            "/>
    </xsl:function>

    <!--
        Whitespace-only text is layout only where the serialization already breaks
        the line. Between two inline siblings (</hi> <PAGE>) it is content:
        dropping it glues words together.
    -->
    <xsl:function name="local:is-layout-whitespace" as="xs:boolean">
        <xsl:param name="node" as="text()"/>
        <xsl:variable name="parent" select="$node/parent::*"/>
        <xsl:variable name="previous" select="local:previous-significant-sibling($node)"/>
        <xsl:variable name="next" select="local:next-significant-sibling($node)"/>
        <xsl:sequence select="
            normalize-space($node) = ''
            and exists($parent)
            and local:is-block-element($parent)
            and (empty($previous)
                 or empty($next)
                 or local:node-ends-with-lf($previous)
                 or local:starts-own-line($next))
            "/>
    </xsl:function>

    <!--
        Indent an end tag only if the content ended with an LF, i.e. the last
        significant child was a block or a comment. Guards against dangling
        indentation after inline children (persName/rs) or a trailing milestone.
    -->
    <xsl:function name="local:should-indent-end-tag" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="
            $node instance of element()
            and local:is-block-element($node)
            and local:node-ends-with-lf(local:last-significant-child($node))
            "/>
    </xsl:function>

    <!-- Inline content following the LF of a block or comment would start at column 0. -->
    <xsl:function name="local:should-indent-after" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:variable name="next" select="local:next-significant-sibling($node)"/>
        <xsl:sequence select="exists($next) and not(local:starts-own-line($next))"/>
    </xsl:function>

    <xsl:template match="/" mode="reflow-ws">
        <xsl:apply-templates mode="reflow-ws"/>
    </xsl:template>

    <xsl:template mode="reflow-ws" match="*[@xml:space='preserve']">
        <xsl:sequence select="string(.)"/>
    </xsl:template>

    <xsl:template mode="reflow-ws" match="text()">
        <xsl:choose>
            <!-- Ignore layout-only whitespace, keep whitespace that is content. -->
            <xsl:when test="local:is-layout-whitespace(.)"/>
            <xsl:otherwise>
                <xsl:sequence select="replace(string(.),'\s+',' ')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template  mode="reflow-ws" match="/comment() | /processing-instruction()">
        <xsl:text>&#xA;</xsl:text>
        <xsl:next-match/>
    </xsl:template>

    <!-- Block elements (with and without mixed content) -->
    <xsl:template mode="reflow-ws" match="*" expand-text="true">
        <xsl:choose>
            <xsl:when test="local:is-block-element(.)">
                <xsl:variable name="me" select="."/>
                <!--LF before start tag if no one has closed before us (giving an LF) -->
                <xsl:text>{ (: conditional LF :) '&#xA;'[local:needs-leading-lf($me)] }</xsl:text>
                <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="reflow-ws"/>
                    <!-- conditionally indent before the end tag -->
                    <xsl:if test="local:should-indent-end-tag(.)">
                        <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
                    </xsl:if>
                </xsl:copy>
                <!--LF after end tag-->
                <xsl:text>&#xA;</xsl:text>
                <!-- indent inline content that follows -->
                <xsl:if test="local:should-indent-after(.)">
                    <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template mode="reflow-ws" match="comment()" expand-text="true">
        <xsl:variable name="me" select="."/>
        <!--LF before start tag if no one has closed before us (giving an LF) -->
        <xsl:text>{ (: conditional LF :) '&#xA;'[local:needs-leading-lf($me)] }</xsl:text>
        <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
        <xsl:copy/>
        <!--LF after end tag-->
        <xsl:text>&#xA;</xsl:text>
        <!-- indent inline content that follows -->
        <xsl:if test="local:should-indent-after(.)">
            <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Milestones -->
    <xsl:template mode="reflow-ws" match="*:lb | *:pb | *:milestone" expand-text="true">
        <xsl:variable name="me" select="."/>
        <!--LF before start tag if no one has closed before us (giving an LF) -->
        <xsl:text>{ (: conditional LF :) '&#xA;'[local:needs-leading-lf($me)] }</xsl:text>
        <xsl:text>{ (: indent :) (ancestor::* ! $indent-ws) => string-join('') }</xsl:text>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="reflow-ws"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
