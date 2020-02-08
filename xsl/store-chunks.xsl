<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xi="http://www.w3.org/2001/XInclude"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:tr="http://transpect.io"
  xmlns:jats="http://jats.nlm.nih.gov"
  version="2.0" exclude-result-prefixes="tr jats xs">
  <xsl:import href="http://transpect.io/xslt-util/uri-to-relative-path/xsl/uri-to-relative-path.xsl"/>
  <xsl:template match="@* | node()" mode="split export">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@xml:base" mode="split"/>
  <xsl:template match="*[parent::*][@xml:base]" mode="split">
    <xsl:element name="xi:include">
      <xsl:attribute name="href" select="@xml:base"/>
    </xsl:element>
  </xsl:template>
  <xsl:template mode="split" match="/*">
    <xsl:apply-templates select="/" mode="toc"/>
    <xsl:apply-templates select="descendant-or-self::*[@xml:base]" mode="export"/>
  </xsl:template>
  <xsl:template match="*[@xml:base]" mode="export">
    <xsl:result-document href="{@xml:base}">
      <xsl:copy>
        <xsl:apply-templates select="@*, node()" mode="split"/>
      </xsl:copy>
    </xsl:result-document>
  </xsl:template>
  <xsl:variable name="root" as="document-node(element(*))" select="/"/>
  <xsl:key name="by-id" match="*[@id]" use="@id"/>
  <xsl:template match="@rid" mode="split" as="attribute(*)+">
    <xsl:variable name="base" select="ancestor::*[@xml:base][1]/@xml:base" as="xs:string"/>
    <xsl:variable name="new-rid" as="attribute(rid)">
      <xsl:attribute name="rid" separator=" ">
        <xsl:for-each select="tokenize(., '\s+', 's')">
          <xsl:variable name="target-base"
            select="key('by-id', ., $root)/ancestor-or-self::*[@xml:base][1]/@xml:base" as="xs:string?"/>
          <xsl:choose>
            <xsl:when test="$target-base and not($base = $target-base)">
              <xsl:sequence select="jats:relative-link($base, $target-base, .)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="."/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:attribute>
    </xsl:variable>
    <xsl:if test="contains($new-rid, '#')">
      <xsl:if test="contains($new-rid, ' ')">
        <xsl:message select="'multi-rid refs to other chunk: ', $new-rid" terminate="yes"/>
      </xsl:if>
      <xsl:apply-templates mode="alt"
        select="key('by-id', replace($new-rid, '^.+#', ''), $root)/ancestor-or-self::*[@xml:base][1]"/>
    </xsl:if>
    <xsl:sequence select="$new-rid"/>
  </xsl:template>
  
  <xsl:function name="jats:relative-link" as="xs:string">
    <xsl:param name="base-uri" as="xs:string"/>
    <xsl:param name="target-uri" as="xs:string"/>
    <xsl:param name="rid" as="xs:string?"/>
    <xsl:variable name="base-dir" select="replace($base-uri, '^(.+)/.+$', '$1')" as="xs:string?"/>
    <xsl:variable name="relative" as="xs:string" select="tr:uri-to-relative-path($base-dir, $target-uri)"/>
    <xsl:sequence select="string-join(($relative, $rid), '#')"/>
  </xsl:function>
  
  <xsl:template match="index | fn" mode="alt toc"/>
  
  <xsl:template match="book-part" mode="alt">
    <xsl:attribute name="alt" separator="">
      <xsl:value-of select="@book-part-type"/>
      <xsl:text xml:space="preserve"> “</xsl:text>
      <xsl:apply-templates select="book-part-meta/title-group/title" mode="#current"/>
      <xsl:text>”</xsl:text>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="/" mode="toc">
    <toc>
      <xsl:apply-templates mode="#current"/>
    </toc>
  </xsl:template>
  
  <xsl:template match="*[@xml:base]" mode="toc">
    <toc-entry>
      <xsl:apply-templates select="@content-type | @book-part-type | @sec-type" mode="#current"/>
      <xsl:apply-templates select="*[1]/descendant-or-self::title |
                                   *[1]/descendant-or-self::book-title" mode="#current"/>
      <ext-link>
        <xsl:attribute name="xlink:href" select="jats:relative-link(/*/@xml:base, @xml:base, ())"/>
      </ext-link>
      <xsl:apply-templates select="descendant::*[@xml:base]" mode="#current"/>
    </toc-entry>
  </xsl:template>
  
  <xsl:template match="title | book-title" mode="toc">
    <xsl:apply-templates select="preceding-sibling::label" mode="#current"/>
    <title>
      <xsl:apply-templates mode="#current"/>
    </title>
    <xsl:apply-templates select="following-sibling::subtitle" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="label | subtitle" mode="toc">
    <xsl:copy>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@book-part-type | @content-type | @sec-type" mode="toc">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>
  
  <xsl:template match="text()" mode="toc"/>
  <xsl:template match="book-title//text() | title//text() | label//text()" mode="toc">
    <xsl:copy/>
  </xsl:template>
</xsl:stylesheet>