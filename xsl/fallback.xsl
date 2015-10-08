<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:jats="http://jats.nlm.nih.gov" xmlns:dbk="http://docbook.org/ns/docbook" xmlns:css="http://www.w3.org/1996/css"
  xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="css jats dbk xs" version="2.0">

  <xsl:import href="http://transpect.io/hub2bits/xsl/hub2bits.xsl"/>

  <xsl:variable name="jats:speech-para-regex" as="xs:string" select="'p_book_speech'"/>
  <xsl:variable name="jats:speaker-regex" as="xs:string" select="'ch_speaker'"/>
  <xsl:variable name="jats:marginal-note-container-style-regex" as="xs:string" select="'^o_sidenote(_-_.+)?$'"/>
  <xsl:variable name="jats:blocklevel-image-container-regex" as="xs:string" select="'^o_image_block(_-_.+)?$'"/>
  
  <!-- General structure. Overridden because of metadata concerns-->
  <xsl:template match="dbk:book | dbk:hub" mode="default" priority="2">
    <book>
      <xsl:namespace name="css" select="'http://www.w3.org/1996/css'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:copy-of select="@css:version"/>
      <xsl:attribute name="css:rule-selection-attribute" select="'content-type style-type'"/>
      <xsl:attribute name="source-dir-uri" select="dbk:info/dbk:keywordset[@role eq 'hub']/dbk:keyword[@role eq 'source-dir-uri']"/>      
      <xsl:sequence select="$dtd-version-att"/>
      <xsl:choose>
        <xsl:when test="@xml:lang">
          <xsl:copy-of select="@xml:lang"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="key('jats:style-by-type', 'NormalParagraphStyle')[@xml:lang ne '']">
            <xsl:copy-of select="key('jats:style-by-type', 'NormalParagraphStyle')/@xml:lang, @xml:lang"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <book-meta>
        <xsl:if test="dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')]">
          <book-id book-id-type="doi">
            <xsl:value-of select="replace(string-join(dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')], ''), '^.+doi\.org/', '')"/>
          </book-id>
          <book-id book-id-type="publisher">
            <xsl:value-of select="replace(string-join(dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_doi')], ''), '^(.+doi\.org/.+/)?(\d{5})-.+$', '$2')"/>
          </book-id>
        </xsl:if>
        <book-title-group>
          <xsl:apply-templates select="dbk:title" mode="#current"/>
          <xsl:apply-templates select="dbk:subtitle" mode="#current"/>
        </book-title-group>
        <xsl:if test="dbk:info/dbk:authorgroup">
          <contrib-group>
            <xsl:apply-templates select="dbk:info/dbk:authorgroup" mode="#current"/>
          </contrib-group>
        </xsl:if>
        <xsl:if test="dbk:info/dbk:seriesvolnums">
          <book-volume-number>
            <xsl:value-of select="dbk:info/dbk:seriesvolnums"/>
          </book-volume-number>
        </xsl:if>
        <xsl:if test="dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_isbn')]">
          <xsl:for-each select="dbk:colophon/dbk:para//dbk:phrase[matches(@role, 'ch_isbn')]">
            <xsl:variable name="type" select="replace(@role, '^.+_ch_isbn_', '')" as="xs:string+"/>
            <isbn publication-format="{$type}">
              <xsl:value-of select="replace(., '\s+\(.+\)$', '')"/>
            </isbn>
          </xsl:for-each>
        </xsl:if>
        <xsl:if test="dbk:info/dbk:publisher/dbk:publishername">
          <publisher>
              <publisher-name>
                <xsl:value-of select="dbk:info/dbk:publisher/dbk:publishername"/>
              </publisher-name>
              <xsl:if test="dbk:info/dbk:publisher/dbk:address">
                <publisher-loc>
                  <xsl:value-of select="dbk:info/dbk:publisher/dbk:address"/>
                </publisher-loc>
              </xsl:if>
          </publisher>
        </xsl:if>
        <xsl:if test="dbk:info/dbk:edition">
          <edition>
            <xsl:value-of select="dbk:info/dbk:edition"/>
          </edition>
        </xsl:if>
        <xsl:if test="dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_publishing_year')] and
                      dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_publisher')]">
          <permissions>
            <copyright-statement>
              <xsl:value-of select="concat('© ', 
                                           string-join(dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_publishing_year')], ''),
                                           '&#160;', 
                                           string-join(dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_publisher(_-_.+)?$')], ''))"/>
            </copyright-statement>
          </permissions>
        </xsl:if>
        <custom-meta-group>
<!--          <xsl:apply-templates select="dbk:info/dbk:keywordset[@role eq 'hub']" mode="#current"/>-->
          <xsl:apply-templates select="dbk:info/css:rules" mode="#current"/>  
        </custom-meta-group>
        <xsl:apply-templates select="dbk:info[dbk:keywordset[@role eq 'hub']]/dbk:keywordset[@role eq 'hub']" mode="#current"/>
      </book-meta>
      <xsl:for-each-group select="*" group-adjacent="jats:matter(.)">
        <xsl:if test="current-grouping-key() ne ''">
          <xsl:element name="{current-grouping-key()}">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:element>
        </xsl:if>
      </xsl:for-each-group>
    </book>
  </xsl:template>

  <xsl:template match="dbk:author | dbk:editor" mode="default">
    <xsl:if test="not(dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_(author|editor)')])">
      <contrib contrib-type="{local-name()}">
        <xsl:call-template name="css:content"/>
      </contrib>
    </xsl:if>
  </xsl:template>
  
<!--  <xsl:template match="dbk:colophon/dbk:para/dbk:phrase[matches(@role, 'ch_(author|editor)')]" mode="default">
    <xsl:choose>
      <xsl:when test="matches(., '\S+')">
        <contrib contrib-type="{replace(@role, 'ch_(author|editor)', '$1')}">
          <string-name test="mimimi">
            <xsl:value-of select="."/>
          </string-name>
        </contrib>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
    
  </xsl:template>-->
  
  <!-- BOXES -->
  <xsl:variable name="jats:box-head-para-style-regex" as="xs:string" select="'box\d_p_head(_-_.+)?$'"/>
  <xsl:variable name="jats:box-para-style-regex" as="xs:string" select="'box\d_p_(text|list\d?|note)(_-_.+)?$'"/>
  
  <!-- Le sigh. Heuristics for box3 due to lack of consistent markup -->
  <xsl:function name="jats:is-box3-heuristically" as="xs:boolean">
    <xsl:param name="table" as="element(dbk:informaltable)"/>
    <xsl:sequence
      select="count($table/dbk:tgroup/dbk:colspec) = 2
                          and (
                                every $c in $table/dbk:tgroup/dbk:tbody/dbk:row/dbk:entry[1] (: changed the path from // otherwise other tables inside are also considered :)
                                satisfies (
                                  matches($c, '^[\s\p{Zs}&#xfeff;]*$') 
                                  and ($c | key('jats:style-by-type', $c/@role, root($table)))/@css:background-color
                                )
                               )"
    />
  </xsl:function>
  
  <xsl:function name="jats:is-not-sidebar-anchor" as="xs:boolean">
    <xsl:param name="anchor" as="element(dbk:anchor)"/>
    <xsl:choose>
      <xsl:when test="$anchor[key('linking-item-by-id', $anchor/@xml:id)[matches(@role, $jats:marginal-note-container-style-regex)]]">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="true()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="dbk:mediaobject[matches(@role, $jats:blocklevel-image-container-regex) or parent::*[self::dbk:section or self::dbk:chapter or self::dbk:appendix]]" mode="default">
    <xsl:element name="fig">
      <xsl:if test="@xml:id">
        <target id="{@xml:id}"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:imageobject[parent::*[self::dbk:mediaobject[matches(@role, $jats:blocklevel-image-container-regex) or parent::*[self::dbk:section or self::dbk:chapter or self::dbk:appendix]]]]" mode="default">
    <xsl:element name="graphic">
      <xsl:apply-templates select="dbk:imagedata/@*" mode="#current"/>
      <!-- http://tickets.le-tex.de/view.php?id=3400 -->
      <xsl:attribute name="content-type" select="'blocklevel-inline'"/>
      <xsl:apply-templates select="dbk:imagedata/node()" mode="#current"/>
      <xsl:if test="../following-sibling::*[1][self::dbk:info][count(*) eq 1][dbk:legalnotice]">
        <xsl:apply-templates select="../following-sibling::*[1]" mode="#current"/>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="permissions[preceding-sibling::*[1][self::fig[graphic[matches(@content-type, 'blocklevel-inline')][permissions]]]]" mode="clean-up"/>
  
  <xsl:template match="dbk:listitem/dbk:figure" mode="default" priority="2">
    <p>
      <xsl:next-match/>
    </p>
  </xsl:template>
  
  <xsl:template match="dbk:figure" mode="default">
    <fig>
      <xsl:call-template name="css:other-atts"/>
      <xsl:apply-templates select="(.//dbk:anchor[jats:is-not-sidebar-anchor(.)][not(jats:is-page-anchor(.))])[1]/@xml:id" mode="#current"/>
      <label>
        <xsl:apply-templates mode="#current" select="dbk:title/dbk:phrase[@role eq 'hub:caption-number']"/>
      </label>
      <caption>
        <title>
          <xsl:apply-templates mode="#current"
            select="dbk:title/(node() except (dbk:phrase[@role eq 'hub:caption-number'] | dbk:tab))"/>
        </title>
        <xsl:if test="dbk:note">
          <xsl:apply-templates select="dbk:note/dbk:para" mode="#current"/>
        </xsl:if>
      </caption>
      <xsl:apply-templates select="* except (dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']] | dbk:note)" mode="#current"/>
      <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
    </fig>
  </xsl:template>
  
  <xsl:template match="dbk:title/dbk:phrase[@role = 'hub:caption-text'][matches(text()[1], '^[\s\p{Zs}]+')]/text()[1]" mode="default">
    <xsl:value-of select="replace(., '^[\s\p{Zs}]+', '')"/>
  </xsl:template>
  
  <xsl:template match="dbk:informaltable[jats:is-box3-heuristically(.)]" mode="default" priority="3">
    <xsl:variable name="head" select="(.//dbk:para[matches(@role, $jats:box-head-para-style-regex)])[1]" as="element(dbk:para)?"/>
    <boxed-text content-type="box3">
      <xsl:apply-templates select="(.//dbk:anchor[jats:is-not-sidebar-anchor(.)][not(jats:is-page-anchor(.))])[1]/@xml:id" mode="#current"/>
      <xsl:call-template name="box-legend"/>
      <xsl:apply-templates select="dbk:alt" mode="#current"/>
      <sec>
        <xsl:if test="$head">
          <xsl:if test="$head[dbk:phrase[@role = 'hub:post-identifier']]">
            <xsl:apply-templates select="$head/dbk:phrase[@role = 'hub:post-identifier']" mode="#current"/>
          </xsl:if>
          <title>
            <xsl:apply-templates select="$head/(@* except @role), $head/node() except ($head/dbk:sidebar, $head/dbk:phrase[@role = 'hub:post-identifier'])" mode="#current"/>
          </title>
        </xsl:if>
        <xsl:apply-templates select="dbk:tgroup/dbk:tbody/dbk:row/dbk:entry/node()" mode="#current"/>
      </sec>
      <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
    </boxed-text>
  </xsl:template>


  <xsl:template match="p[matches(@content-type, 'p_box_title')][preceding-sibling::*[self::boxed-text] or following-sibling::*[self::boxed-text]]" mode="clean-up"/>

<!--  <xsl:template match="*:boxed-text[preceding-sibling::*[1][self::*:p[matches(@content-type, 'p_box_title')]] or following-sibling::*[1][self::*:p[matches(@content-type, 'p_box_title')]]]" mode="default">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <caption>
        <xsl:copy-of select="(preceding-sibling::*[1][self::*:p[matches(@content-type, 'p_box_title')]], preceding-sibling::*[1][self::*:p[matches(@content-type, 'p_box_title')]])[1]"/>
      </caption>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>-->
  
  <xsl:variable name="box-title-before-box" select="count(/*//dbk:para[matches(@role, 'p_box_title')]
                                                                      [following-sibling::*[1][self::dbk:informaltable or 
                                                                       self::dbk:sidebar[matches(@role, 'o_sidenote')][following-sibling::*[1][self::dbk:informaltable]]]]
                                                            ) gt 
                                                     count(/*//dbk:para[matches(@role, 'p_box_title')]
                                                                      [preceding-sibling::*[1][self::dbk:informaltable  
                                                                      or self::dbk:sidebar[matches(@role, 'o_sidenote')][preceding-sibling::*[1][self::dbk:informaltable]]]]
                                                           )" as="xs:boolean"/>
  <xsl:template name="box-legend">
    <xsl:if test="preceding-sibling::*[1][self::dbk:para[matches(@role, 'p_box_title')] or self::dbk:sidebar[matches(@role, 'o_sidenote')][preceding-sibling::*[1][self::dbk:para[matches(@role, 'p_box_title')]]]] or 
                  following-sibling::*[1][self::dbk:para[matches(@crole, 'p_box_title')] or self::dbk:sidebar[matches(@role, 'o_sidenote')][following-sibling::*[1][self::dbk:para[matches(@role, 'p_box_title')]]]]">
      <xsl:variable name="legend" select="if ($box-title-before-box) 
                                          then (preceding-sibling::*[1][self::dbk:para[matches(@role, 'p_box_title')]], preceding-sibling::*[2][self::dbk:para[matches(@role, 'p_box_title')][following-sibling::*[1][self::dbk:sidebar[matches(@role, 'o_sidenote')]]]])[1] 
                                          else (following-sibling::*[1][self::dbk:para[matches(@role, 'p_box_title')]], following-sibling::*[2][self::dbk:para[matches(@role, 'p_box_title')][preceding-sibling::*[1][self::dbk:sidebar[matches(@role, 'o_sidenote')]]]])[1]" as="element(dbk:para)*"/>
      <xsl:if test="$legend[*:phrase[@role = 'hub:identifier']]">
          <xsl:apply-templates select="$legend/*:phrase[@role = 'hub:identifier']" mode="#current"/>
      </xsl:if>
      <caption>
        <xsl:apply-templates select="$legend" mode="#current">
          <xsl:with-param name="discard-identifier" tunnel="yes" select="true()" as="xs:boolean"/>
        </xsl:apply-templates>
      </caption>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="dbk:para[matches(@role, 'p_box_title')]/*:phrase[@role = 'hub:identifier']" mode="default">
    <xsl:param name="discard-identifier" as="xs:boolean?" tunnel="yes"/>
    <xsl:if test="not($discard-identifier)">
      <label>
        <xsl:apply-templates select="node()" mode="#current"/>
      </label>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="dbk:informaltable[some $r in .//dbk:para/@role satisfies (matches($r, $jats:box-para-style-regex))]"
    mode="box-type">
    <xsl:sequence
      select="replace( (.//dbk:para/@role[matches(., $jats:box-para-style-regex)])[1], '^.*(box\d)_p_(head|list|note|text).*', '$1' )"/>
  </xsl:template>

  <!-- special template for boxes that look like box1 but have several headings (Leitlinien)-->
  <xsl:template match="dbk:informaltable[some $r in .//dbk:para/@role satisfies (matches($r, 'box6'))]
                                        [.//dbk:row[dbk:entry/dbk:para[matches(@role, $jats:box-head-para-style-regex)]]]" mode="default" priority="3">
    <boxed-text content-type="box6">
      <xsl:apply-templates select="(.//dbk:anchor[jats:is-not-sidebar-anchor(.)][not(jats:is-page-anchor(.))])[1]/@xml:id" mode="#current"/>
      <xsl:call-template name="box-legend"/>
      <xsl:apply-templates select="dbk:alt" mode="#current"/>
      <xsl:for-each-group select=".//dbk:row" group-starting-with="dbk:row[dbk:entry/dbk:para[matches(@role, $jats:box-head-para-style-regex)]]">
        <xsl:variable name="head" select="(current-group()//dbk:para[matches(@role, $jats:box-head-para-style-regex)])[1]" as="element(dbk:para)+"/>

        <sec>
          <xsl:if test="$head">
            <xsl:if test="$head[dbk:phrase[@role = 'hub:post-identifier']]">
              <xsl:apply-templates select="$head/dbk:phrase[@role = 'hub:post-identifier']" mode="#current"/>
            </xsl:if>
            <title>
              <xsl:apply-templates select="$head/(@* except @role), $head/node() except ($head/dbk:sidebar, $head/dbk:phrase[@role = 'hub:post-identifier'])" mode="#current"/>
            </title>
            <!-- Marginals -->
            <xsl:apply-templates select="$head/dbk:sidebar" mode="#current"/>
          </xsl:if>
          <xsl:apply-templates select="current-group()//dbk:entry/node()[not(. is $head)]" mode="#current"/>
        </sec>
      </xsl:for-each-group>
    </boxed-text>
  </xsl:template>

  <xsl:template match="dbk:para[matches(@role, $jats:box-head-para-style-regex)][matches(@role, 'box6')]" mode="default" priority="5">
    <title>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </title>
 </xsl:template>
  
  <xsl:template match="dbk:informaltable[some $r in .//dbk:para/@role satisfies (matches($r, $jats:box-para-style-regex))][not(count(ancestor::dbk:informaltable) gt 0)]"
    priority="2" mode="default">
    <xsl:variable name="head" select="(.//dbk:para[matches(@role, $jats:box-head-para-style-regex)])[1]" as="element(dbk:para)?"/>
    <xsl:variable name="box-symbol" as="element(dbk:imagedata)?" select="$head/parent::*/preceding-sibling::*[1]//dbk:mediaobject/dbk:imageobject/dbk:imagedata"/>
    <boxed-text content-type="{jats:box-type(.)}">
      <xsl:apply-templates select="($head//dbk:anchor[jats:is-not-sidebar-anchor(.)][not(jats:is-page-anchor(.))])[1]/@xml:id" mode="#current"/>
      <xsl:call-template name="box-legend"/>
      <xsl:apply-templates select="dbk:alt" mode="#current"/>
      <sec>
        <xsl:if test="$head">
          <xsl:if test="$head[dbk:phrase[@role = 'hub:post-identifier']]">
            <xsl:apply-templates select="$head/dbk:phrase[@role = 'hub:post-identifier']" mode="#current"/>
          </xsl:if>
          <title>
            <xsl:apply-templates select="$head/(@* except @role)" mode="#current"/>
            <xsl:if test="$box-symbol">
              <xsl:element name="inline-graphic">
                <xsl:apply-templates select="$box-symbol/@fileref" mode="#current"/>
                <xsl:attribute name="id" select="$box-symbol/@xml:id"/>
                <xsl:attribute name="css:width" select="$box-symbol/@css:width"/>
                <xsl:attribute name="css:height" select="$box-symbol/@css:height"/>
              </xsl:element>
            </xsl:if>
            <xsl:apply-templates select="$head/node() except ($head/dbk:sidebar, $head/dbk:phrase[@role = 'hub:post-identifier'])" mode="#current"/>
          </title>
        </xsl:if>
        <xsl:apply-templates select="$head/dbk:sidebar" mode="#current"/>
        <xsl:apply-templates select=".//dbk:entry/*[not(. is $head) and not(./*[1]/*[1] is $box-symbol) and not(count(ancestor::dbk:informaltable) gt 1)]" mode="#current"/>
        <xsl:apply-templates select=".//dbk:entry/*[. is $box-symbol]" mode="test"/>
      </sec>
      <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
    </boxed-text>
  </xsl:template>

  <xsl:template match="*" mode="test"/>

  <xsl:template match="*:phrase[@role = 'hub:post-identifier']" mode="default">
    <label>
      <named-content content-type="post-identifier">
       <xsl:apply-templates select="node()" mode="#current"/>
      </named-content>
    </label>
  </xsl:template>
  
  <!-- single-cell tables that only contain poetry -->
  <xsl:template match="dbk:figure/dbk:informaltable[count(.//dbk:entry) eq 1][.//dbk:entry[count(*) eq 1]/dbk:poetry]"
    mode="default">
    <xsl:apply-templates select=".//dbk:entry/dbk:poetry" mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:sidebar[some $r in .//dbk:para/@role satisfies (matches($r, $jats:box-para-style-regex))]"
    mode="box-type">
    <xsl:sequence
      select="replace( (.//dbk:para/@role[matches(., $jats:box-para-style-regex)])[1], '^.*(box\d)_p_(head|note|list|text).*', '$1' )"/>
  </xsl:template>

  <xsl:template
    match="dbk:sidebar[@remap eq 'TextFrame']
                                  [some $r in .//dbk:para/@role satisfies (matches($r, $jats:box-para-style-regex))]"
    mode="default">
    <xsl:variable name="head" select="(.//dbk:para[matches(@role, $jats:box-head-para-style-regex)])[1]" as="element(dbk:para)?"/>
    <boxed-text content-type="{jats:box-type(.)}">
      <xsl:apply-templates select="($head//dbk:anchor)[1]/@xml:id" mode="#current"/>
      <sec>
       <xsl:if test="$head">
         <xsl:if test="$head[dbk:phrase[@role = 'hub:post-identifier']]">
           <xsl:apply-templates select="$head/dbk:phrase[@role = 'hub:post-identifier']" mode="#current"/>
         </xsl:if>
          <title>
            <xsl:apply-templates select="$head/(@* except @role), $head/(node()[not(self::dbk:phrase[@role = 'hub:post-identifier'])])" mode="#current"/>
          </title>
        </xsl:if>
        <xsl:apply-templates mode="#current"/>
      </sec>
    </boxed-text>
  </xsl:template>

  <xsl:template match="dbk:para[matches(@role, $jats:box-head-para-style-regex)]" mode="default"/>
  <xsl:template match="dbk:title[matches(@role, 'virtual')][matches(., '^\s*$')]" mode="default" priority="1.5"/>

  <!-- SIDEBARS (MARGINALIA) -->

  <xsl:template
    match="dbk:sidebar[@remap eq 'TextFrame']
    [dbk:para[matches(@role, 'p_margin')]]
    [every $c in * satisfies ($c/self::dbk:para[matches(@role, 'p_margin')])]"
    mode="default">
    <boxed-text content-type="marginalia" position="margin">
      <xsl:if test="@linkend">
        <xsl:attribute name="id" select="@linkend"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current"/>
    </boxed-text>
  </xsl:template>

  <!-- for finding sidebar[@linkend] to a given anchor[@xml:id]: -->
  <xsl:key name="linking-item-by-id" match="boxed-text[@content-type[. = 'marginalia']] | dbk:sidebar[@role[matches(., $jats:marginal-note-container-style-regex)]]" use="@id, @linkend" />

  <!-- sidebars have to be moved into table paras -->
  <xsl:template match="p[ancestor::*[self::td]][.//target[key('linking-item-by-id', @id)]]"
    mode="clean-up">
    <xsl:variable name="sidenote-anchor" as="element(target)+" select=".//target[key('linking-item-by-id', @id)]"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:choose>
        <xsl:when test="$sidenote-anchor is current()/*[1]">
          <xsl:apply-templates select="key('linking-item-by-id', $sidenote-anchor/@id)" mode="#current">
            <xsl:with-param name="discard-sidebar" as="xs:boolean" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
          <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="node()" mode="#current"/>
          <xsl:apply-templates select="key('linking-item-by-id', $sidenote-anchor/@id)" mode="#current">
            <xsl:with-param name="discard-sidebar" as="xs:boolean" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="boxed-text[@content-type = 'marginalia'][ancestor::*[self::td]]"
    mode="clean-up">
    <xsl:param name="discard-sidebar" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$discard-sidebar">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>
  
  <!-- TABLES -->

  <!-- Special Tables with lists à la Niemiec 101027_00376_ADHOC Table 2.1 -->

  <xsl:template match="dbk:sidebar[@role = 'o_table']" mode="default">
    <table-wrap>
      <xsl:apply-templates select="@xml:id" mode="#current"/>
      <xsl:for-each select="dbk:title">
        <xsl:call-template name="dbk:table-title"/>
      </xsl:for-each>
      <xsl:variable name="footer-content" as="element(*)*" select="dbk:para[matches(@role, 'p_(table_)?copyright_statement')]"/>
      <xsl:apply-templates select="* except ($footer-content union dbk:title)" mode="#current"/>
      <xsl:if test="$footer-content">
        <table-wrap-foot>
          <xsl:apply-templates select="$footer-content" mode="default"/>
        </table-wrap-foot>
      </xsl:if>
    </table-wrap>
  </xsl:template>

<!--  <xsl:template match="dbk:para[matches(@role, 'p_(table_)?copyright_statement')]" mode="default">
    <permissions>
      <copyright-statement>
        <xsl:apply-templates select="@* except @role, node()" mode="#current"/>
      </copyright-statement>
    </permissions>
  </xsl:template>-->


  <!-- Ignore this. It’s inaccurate anyway because it doesn’t take table styles into account.
       Styles will be taken from CSSa. -->
  <xsl:template match="@frame" mode="default"/>

  <!-- RUNNING HEADS -->

  <xsl:template match="dbk:para[matches(@role, 'master_page_objects_p_column')]" mode="default"/>
  <xsl:template match="dbk:para[matches(@role, 'master_page_objects_p_runninghead')]" mode="default"/>

  <!-- INLINE -->

  <xsl:template
    match="dbk:phrase/@role[matches(., '^(
    ch_(column_(left|right)|lit)
    | No_character_style
    | hub:(caption-number|identifier)
    )', 'x')]"
    mode="default"/>

  <xsl:variable name="keep-br-regex" as="xs:string" select="'p_(figure_text|text_verse|list|blockquote|quotation)'"/>
  <!-- This is a problem. No breaks are allowed in paras -.- -->
  <xsl:template match="dbk:br[not(ancestor::dbk:title)]" mode="default">
    <xsl:choose>
      <xsl:when test="ancestor::dbk:para[matches(@role, $keep-br-regex)]">
        <xsl:next-match/>
      </xsl:when>
      <xsl:when test="ancestor::dbk:para/preceding-sibling::dbk:title[1][matches(@role, 'appendix_p_h_bios')]">
        <xsl:next-match/>
      </xsl:when>
      <xsl:when test="not(preceding-sibling::node()[matches(., '\s$')] or following-sibling::node()[matches(., '^\s')])">
        <xsl:text xml:space="preserve"> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <!-- discard -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="dbk:personblurb/dbk:para//dbk:anchor" mode="default" priority="2"/>
  
  <!-- FOOTNOTES -->

  <xsl:template match="dbk:footnote/@role" mode="default"/>

  <!-- BIBLIOGRAPHY -->

  <xsl:template match="dbk:phrase/@css:text-decoration-line[. = ('none', 'underline') and ../contains(@role, 'xref') ]" mode="default"/>

  <xsl:template match="dbk:phrase[contains(@role, 'xref_given_names') or contains(@role, 'xref_editor_given_name')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <given-names>
      <xsl:attribute name="type" select="if (contains(@role, 'xref_given_names')) then 'author' else 'editor'"/>
      <xsl:apply-templates mode="#current" select="@* except @xml:lang, node()"/>
    </given-names>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'xref_surname') or matches(@role, 'xref_editor_(sur)?name')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <surname>
      <xsl:attribute name="type" select="if (contains(@role, 'xref_surname')) then 'author' else 'editor'"/>
      <xsl:apply-templates mode="#current" select="@* except @xml:lang"/>
      <!-- extra template, whitespace not merged into name -->
     <!-- <xsl:if test="(preceding-sibling::*[1][self::dbk:phrase[matches(@role, 'ch_xref_(editor_)?prefix')]]) or
        (preceding-sibling::*[1][self::dbk:phrase[matches(@role, 'ch_xref_other')]] and preceding-sibling::*[2][self::dbk:phrase[matches(@role, 'ch_xref_(editor_)?prefix')]])">
        <xsl:apply-templates select="(preceding-sibling::*[1][self::dbk:phrase[matches(@role, 'ch_xref_(editor_)?prefix')]], 
                                     (preceding-sibling::*[2][self::dbk:phrase[matches(@role, 'ch_xref_(editor_)?prefix')]], preceding-sibling::*[1][self::dbk:phrase[matches(@role, 'ch_xref_other')]]))"/> 
      </xsl:if>-->
      <xsl:apply-templates mode="#current" select="node()"/>
    </surname>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[matches(@role, 'ch_xref_other')][preceding-sibling::*[1][self::dbk:phrase[matches(@role, 'ch_xref_(editor_)?prefix')]]][parent::*[self::dbk:bibliomisc]]" mode="default" priority="2.5">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[matches(@role, 'ch_xref_(editor_)?prefix')][parent::*[self::dbk:bibliomisc]]" mode="default" priority="2.5">
    <prefix>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </prefix>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[matches(@role, 'ch_xref_series')][parent::*[self::dbk:bibliomisc]]" mode="default" priority="2.5">
    <series>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </series>
  </xsl:template>
  
  <xsl:template match="dbk:phrase/@role[contains(., 'xref')]" mode="default" priority="-1"/>

  <xsl:template match="@css:text-decoration-line[. = 'underline'][ancestor::*[self::dbk:biblioentry]]" mode="default"/>

  
  <!-- works for css:rule/@name as well as for dbk:phrase/@role, dbk:para/@role, etc.
       The resulting attribute will be created 4 times identically (for -line, -offset, -width, and -color), 
       but so what.  -->
  <xsl:template match="*/@*[starts-with(name(), 'css:text-decoration')]
                                          [../@css:text-decoration-color]
                                          [number(replace((../@css:text-decoration-width, '0')[1], 'pt', '')) gt 9]"
                                          mode="default">
    <xsl:attribute name="css:background-color" select="../@css:text-decoration-color"/>
  </xsl:template>
  
  <xsl:template match="css:rule[contains(@name, 'xref')]/@css:background-color | css:rule[contains(@name, 'xref')]/@*[matches(name(), '^css:text-decoration')]" mode="default" priority="3"/>

  <!-- this is to suppress <underline> generation for the case handled above -->
  <xsl:template match="*/@css:text-decoration-line
    [../@css:text-decoration-color]
    [number( replace((../@css:text-decoration-width, '0')[1], 'pt', '')) gt 9]" mode="css:map-att-to-elt"
    as="xs:string?"/>  

  <xsl:template match="dbk:phrase[contains(@role, 'xref_article_title')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <article-title>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </article-title>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'xref_chapter_title')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <chapter-title>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </chapter-title>
  </xsl:template>

  <xsl:template match="dbk:phrase[contains(@role, 'ch_xref_trans_title')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <trans-title>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </trans-title>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'ch_xref_trans_subtitle')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <trans-subtitle>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </trans-subtitle>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'ch_xref_comment')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <xsl:choose>
      <xsl:when test="ancestor::*[self::dbk:link]">
        <xsl:apply-templates select="node()" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <comment>
          <xsl:apply-templates mode="#current" select="@*, node()"/>
        </comment>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'xref_date')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <xsl:choose>
      <xsl:when test="matches(., '^\d{4}$')">
        <year>
          <xsl:apply-templates mode="#current" select="@*, node()"/>
        </year>
      </xsl:when>
      <xsl:when test="matches(., '(I|i)n\s(P|p)ress')">
        <comment>
          <xsl:apply-templates mode="#current" select="@*, node()"/>
        </comment>
      </xsl:when>      
      <xsl:otherwise>
        <string-date>
          <xsl:apply-templates mode="#current" select="@*, node()"/>
        </string-date>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>

  <xsl:template match="dbk:phrase[contains(@role, 'xref_publisher_loc')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <publisher-loc>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </publisher-loc>
  </xsl:template>

  <xsl:template match="dbk:phrase[contains(@role, 'xref_publisher_name')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <publisher-name>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </publisher-name>
  </xsl:template>

  <xsl:template match="dbk:phrase[contains(@role, 'xref_edition')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <edition>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </edition>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'xref_collab')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <collab>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </collab>
  </xsl:template>

  <xsl:template match="dbk:biblioentry//dbk:phrase[contains(@role, 'xref_etal')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <etal>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </etal>
  </xsl:template>

  <xsl:template match="dbk:phrase[matches(@role, 'xref_(book_)?volume$')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <volume>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </volume>
  </xsl:template>

  <xsl:template match="dbk:phrase[matches(@role, '(xref_volume_series|xref_issue)')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <issue>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </issue>
  </xsl:template>

  <xsl:template match="dbk:phrase[contains(@role, 'xref_fpage')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <fpage>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </fpage>
  </xsl:template>

  <xsl:template match="dbk:phrase[contains(@role, 'xref_lpage')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <lpage>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </lpage>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'xref_role')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <role>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </role>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'ch_xref_source')][parent::*[self::dbk:bibliomisc]]" mode="default">
        <source>
          <xsl:apply-templates mode="#current" select="@*, node()"/>
        </source>
  </xsl:template>
   
  <xsl:template match="dbk:phrase[matches(@role, 'ch_xref_source')][matches(., '^,[\s\p{Zs}]+$')][parent::*[self::dbk:bibliomisc]]" mode="default" priority="2">
    <source>
    <xsl:apply-templates mode="#current"/>
    </source>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'ch_xref_trans_source')][parent::*[self::dbk:bibliomisc]]" mode="default">
    <trans-source>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </trans-source>
  </xsl:template>
  
  <xsl:template match="dbk:phrase[contains(@role, 'xref_other')][every $a in @* satisfies local-name($a) = ('role', 'srcpath')][parent::*[self::dbk:bibliomisc]]" mode="default">
      <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:link[contains(@xlink:href, 'doi.org')][not(ancestor::*[self::dbk:colophon])]" mode="default">
    <pub-id pub-id-type="doi">
      <xsl:if test="@srcpath | dbk:phrase/@srcpath">
        <xsl:attribute name="srcpath" select="@srcpath | dbk:phrase/@srcpath" separator=" "/>
      </xsl:if>
      <xsl:value-of select="replace(., '^\s*https?://(dx\.)?doi\.org/', '')"/>
    </pub-id>
  </xsl:template>

  <xsl:template match="dbk:phrase[matches(., '(doi:|https?://(dx\.)?doi\.org)') and @role and dbk:link][ancestor::*[self::dbk:bibliomisc]]" priority="2" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- For checking reasons: highlighting the reference tags in the html -->
 <!-- <xsl:template match="css:rule/@name" mode="clean-up">
    <xsl:choose>
      <xsl:when test="contains(., 'xref_fpage')">
        <xsl:attribute name="name" select="'fpage'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_lpage')">
        <xsl:attribute name="name" select="'lpage'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_source')">
        <xsl:attribute name="name" select="'source'"/>
      </xsl:when> 
      <xsl:when test="contains(., 'xref_issue')">
        <xsl:attribute name="name" select="'issue'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_volume_series')">
        <xsl:attribute name="name" select="'volume-series'"/>
      </xsl:when>
      <xsl:when test="matches(., 'xref_volume$')">
        <xsl:attribute name="name" select="'volume'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_editor_name')">
        <xsl:attribute name="name" select="'editor'"/>
      </xsl:when>      
      <xsl:when test="contains(., 'xref_etal')">
        <xsl:attribute name="name" select="'etal'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_edition')">
        <xsl:attribute name="name" select="'edition'"/>
      </xsl:when>   
      <xsl:when test="contains(., 'xref_publisher_name')">
        <xsl:attribute name="name" select="'publisher-name'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_publisher_loc')">
        <xsl:attribute name="name" select="'publisher-loc'"/>
      </xsl:when>   
      <xsl:when test="contains(., 'xref_chapter_title')">
        <xsl:attribute name="name" select="'chapter-title'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_article_title')">
        <xsl:attribute name="name" select="'article-title'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_given_names')">
        <xsl:attribute name="name" select="'given-names'"/>
      </xsl:when>  
      <xsl:when test="contains(., 'xref_surname')">
        <xsl:attribute name="name" select="'surname'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_date')">
        <xsl:attribute name="name" select="'year'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_role')">
        <xsl:attribute name="name" select="'role'"/>
      </xsl:when>
      <xsl:when test="contains(., 'ch_xref_comment')">
        <xsl:attribute name="name" select="'comment'"/>
      </xsl:when>
      <xsl:when test="contains(., 'xref_collab')">
        <xsl:attribute name="name" select="'xref_collab'"/>
      </xsl:when>
      <xsl:when test="contains(., 'ch_xref_trans_title')">
        <xsl:attribute name="name" select="'xref_trans_title'"/>
      </xsl:when>
      <xsl:when test="contains(., 'ch_xref_trans_subtitle')">
        <xsl:attribute name="name" select="'xref_trans_subtitle'"/>
      </xsl:when>
      <xsl:when test="contains(., 'ch_xref_trans_source')">
        <xsl:attribute name="name" select="'xref_trans_source'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="name" select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>-->
  
  <!-- nonsensical links e.g. in ADHOC_MO 02458, probably due to undiscriminatingly 
    running citation-by-author-name detection -->
  <xsl:template match="dbk:biblioentry//dbk:link[@linkend]" mode="default" priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
    
  <!-- in ADHOC_MO 02458, there were ch_xref_comment phrases among ch_xref_doi (if the DOI contained
    square brackets). If there’s already a link, ignore these phrases. -->
  <xsl:template match="dbk:link[contains(@xlink:href, 'doi.org')]/dbk:phrase" mode="default" priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="  dbk:bibliomisc/dbk:phrase[not(@role) or matches(@role, 'ch_text((_bold)?(_italic)?)')] 
                       | dbk:phrase[not(@role) or matches(@role, 'ch_text((_bold)?(_italic)?)')][ancestor::mixed-citation]" mode="#all">
      <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:function name="jats:is-string-name-content" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:choose>
      <xsl:when test="local-name($node) = ('surname', 'given-names', 'prefix')">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when
        test="$node/(self::text() | self::*:styled-content)[matches(., '^,[\s\p{Zs}]+$', 's')]
                                                           [preceding-sibling::*[1]/self::*:surname[@type = 'author']]
                                                           [following-sibling::*[1]/(self::*:given-names)]">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <!-- <surname>Gontard</surname>, <given-names>A.</given-names> <prefix>von</prefix> -->
      <xsl:when
        test="$node/(self::text() | self::*:styled-content)[matches(., '^\p{Zs}+$', 's')]
                                                           [preceding-sibling::*[1]/self::*:given-names]
                                                           [following-sibling::*[1]/(self::*:surname[@type = 'author'] | self::*:prefix)]">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <!-- <prefix>von</prefix> <surname>Gontard</surname>, <given-names>A.</given-names>-->
      <xsl:when
        test="$node/(self::text() | self::*:styled-content)[matches(., '^\p{Zs}+$', 's')]
                                                           [preceding-sibling::*[1]/self::*:prefix]
                                                           [following-sibling::*[1]/self::*:surname[@type = 'author']]">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <!-- editors: <given-names>A.</given-names> <surname>Gontard</surname> -->
      <xsl:when test="$node/(self::text() | self::*:styled-content)[matches(., '^\p{Zs}+$', 's')]
                                                                   [preceding-sibling::*[1]/self::*:given-names]
                                                                   [following-sibling::*[1]/(self::*:surname[@type = 'editor'] | self::*:prefix)]">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="$node/(self::text() | self::*:styled-content)[matches(., '^\p{Zs}+$', 's')]
                                                                   [preceding-sibling::*[1]/self::*:prefix]
                                                                   [following-sibling::*[1]/self::*:surname[@type = 'editor']]">
         <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="jats:is-person-group-content" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:choose>
      <xsl:when test="local-name($node) = ('string-name', 'etal')">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="local-name($node) = ('given-names') and $node/preceding-sibling::node()[1][matches(., 'In\s')]">
        <xsl:sequence select="true()"/>
      </xsl:when>
     <xsl:when test="$node/(self::text() | self::*:styled-content) 
                     and
                     (
                       $node/preceding-sibling::*[1]/self::*:string-name 
                       and 
                       $node/following-sibling::*[1]/local-name() = ('string-name', 'etal')
                     )">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>  
  
  <xsl:template match="* | @*" mode="ref1 join-source normalize-left normalize-right">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="mixed-citation" mode="clean-up">
    <xsl:variable name="pass1" as="element(mixed-citation)">
      <xsl:apply-templates select="." mode="normalize-left">
        <xsl:with-param name="context" select="." as="element(*)" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="pass2" as="element(mixed-citation)">
      <xsl:apply-templates select="$pass1" mode="join-source">
        <xsl:with-param name="root" select="root()" as="document-node(element(*))" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="pass3" as="element(mixed-citation)">
      <xsl:apply-templates select="$pass2" mode="normalize-right">
        <xsl:with-param name="context" select="." as="element(*)" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="pass4" as="element(mixed-citation)">
      <xsl:apply-templates select="$pass3" mode="ref1">
        <xsl:with-param name="root" select="root()" as="document-node(element(*))" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
<!--    <xsl:sequence select="$pass1"/>-->
    <xsl:apply-templates select="$pass4" mode="ref2">
      <xsl:with-param name="root" select="root()" as="document-node(element(*))" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:variable name="exclude-from-ref-normalization" as="xs:string+"
    select="('mixed-citation')"/>
  
  <xsl:template match="*[not(name() = $exclude-from-ref-normalization)]
                        [matches(., '^[\p{Pd}\p{Po}\p{Zs}\s]+$')]" mode="normalize-left" priority="3">
    <xsl:value-of select="."/>
  </xsl:template>
    
  <xsl:template match="*[not(name() = $exclude-from-ref-normalization)][text()]" 
    mode="normalize-left" priority="2">
    <xsl:value-of select="replace(text()[1], '^([\p{Po}\p{Zs}\s]+)?.+$', '$1')"/>
    <xsl:next-match/>
  </xsl:template>

  <xsl:template match="*[not(name() = $exclude-from-ref-normalization)]/text()[1]" mode="normalize-left">
    <xsl:value-of select="replace(., '^[\p{Po}\p{Zs}\s]+', '')"/>
  </xsl:template>

  <xsl:template match="*[not(name() = ($exclude-from-ref-normalization))][text()]" 
    mode="normalize-right" priority="2">
    <xsl:next-match/>
    <xsl:value-of select="replace(text()[last()][matches(., '[,;\p{Zs}\s]$')], '^.+?([,;\p{Zs}\s]+)?$', '$1')"/>
  </xsl:template>
  
  <xsl:template match="*[not(name() = ($exclude-from-ref-normalization))]/text()[last()][matches(., '[,;\p{Zs}\s]$')]" 
    mode="normalize-right">
    <xsl:value-of select="replace(., '([,;\p{Zs}\s]+)$', '')"/>
  </xsl:template>
  
  <xsl:template match="*[source]" mode="join-source">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" 
        group-adjacent="self::source 
                        or 
                        self::text() 
                          [matches(., '^[\p{Pd}\p{Po}\p{Zs}\s]+$')]
                          [preceding-sibling::*[1]/self::source and following-sibling::*[1]/self::source]">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:comment>start true</xsl:comment>
            <xsl:copy>
              <xsl:apply-templates select="@*" mode="#current"/>
              <xsl:apply-templates select="current-group()/(node() | self::text())" mode="#current"/>
            </xsl:copy>
            <xsl:comment>end true</xsl:comment>
          </xsl:when>
          <xsl:otherwise>
            <xsl:comment>start false</xsl:comment>            
            <xsl:apply-templates select="current-group()" mode="#current"/>
            <xsl:comment>end false</xsl:comment>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="mixed-citation" mode="ref1">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:for-each-group select="node()" group-adjacent="jats:is-string-name-content(.)">
          <xsl:choose>
            <xsl:when test="current-grouping-key()">
              <string-name type="{distinct-values(current-group()/@type)}">
                <xsl:apply-templates select="current-group()" mode="#current"/>
              </string-name>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <!-- remove elements that are empty (after whitespace/punctuation normalization): -->
  <xsl:template match="*[name() = ('article-title', 'source', 'styled-content')][empty(.)]" mode="clean-up" priority="2"/>

  <xsl:template match="mixed-citation" mode="ref2">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="clean-up"/>
      <xsl:for-each-group select="node()" group-adjacent="jats:is-person-group-content(.)">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <person-group person-group-type="{distinct-values(current-group()/@type)}">
              <xsl:apply-templates select="current-group()" mode="clean-up"/>
            </person-group>
          </xsl:when>
          <xsl:otherwise>
<!--            <xsl:processing-instruction name="was" select="string-join(('|', current-group(), '|'), '')"></xsl:processing-instruction>-->
            <xsl:apply-templates select="current-group()" mode="clean-up"/>
          </xsl:otherwise>
        </xsl:choose>
        </xsl:for-each-group>
    </xsl:copy>
 </xsl:template>

  <xsl:template match="surname/@type | given-names/@type | string-name/@type" mode="clean-up ref1 ref2"/>
  
  <!-- Perhaps later managed by improved reference structuring script -->
  
  <xsl:template match="dbk:anchor" mode="ref1">
    <target><xsl:call-template name="css:content"/></target>
  </xsl:template>

  <xsl:template match="dbk:anchor/@xml:id" mode="ref1">
    <xsl:attribute name="id" select="."/>
  </xsl:template>
  
  <xsl:template match="mixed-citation/child::*[matches(., '^\s?\p{P}\s?$')][not(self::*:phrase)]" mode="clean-up">
     <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="mixed-citation/@content-type[contains(., 'p_ref')]" mode="ref1" priority="1">
    <xsl:attribute name="publication-type" select="if (contains(., 'p_ref_'))
      then replace(replace(., '^.*p_ref_(.*)$', '$1'), '(\p{L})_((\p{L}))', '$1-$2') 
                                                   else ''"/>
  </xsl:template>

  <xsl:template match="sec/@content-type[. = 'unknown'][ancestor::dark-matter]" mode="clean-up"/>
  
  <xsl:template match="@xml:lang[parent::*[local-name() = ('sup', 'sub')]]" mode="clean-up"/>
  
  <xsl:template match="break[ancestor::*[self::p]][ancestor::*[self::p][not(matches(@content-type, $keep-br-regex))]]" mode="clean-up"/>
  
  <xsl:template match="ext-link[source or publisher-name or article-title or volume-series or chapter-title or issue][count(*) eq 1]"  mode="clean-up">
    <xsl:element name="{name(*)}">
      <xsl:copy-of select="*/@srcpath" />
      <xsl:copy>
        <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:apply-templates select="node() except *" mode="#current"/>
        <xsl:apply-templates select="*/node()" mode="#current"/>
      </xsl:copy>
    </xsl:element>
  </xsl:template>

  <xsl:template match="ext-link[matches(@xlink:href, '@')]" mode="clean-up">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>

  <!-- due to malfunctions of the literature structuring script -->

  <xsl:template match="*[local-name() = ('role', 'comment', 'volume')][not(ancestor::mixed-citation)]" mode="clean-up">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>

  <xsl:template match="app-group" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node() except index" mode="#current"/>
    </xsl:copy>
    <xsl:apply-templates select="index" mode="#current"/>
  </xsl:template>
  
  
  <!-- a template to use the print-index. To use it, set the parameter to true in evolve-hub/hub2hobots and jats2html title specific adaptions -->
  
  <xsl:param name="use-print-index" as="xs:boolean" select="false()"/>
  
  <xsl:template match="dbk:index[$use-print-index]" mode="default" priority="3">
    <index>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </index>
  </xsl:template>

</xsl:stylesheet>