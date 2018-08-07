<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:jats="http://jats.nlm.nih.gov"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:functx="http://www.functx.com"
  xmlns:hub2htm="http://transpect.io/hub2htm"
  xmlns:hub="http://transpect.io/hub"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  
  exclude-result-prefixes="css dbk functx jats xs xlink hub hub2htm mml"
  version="2.0">

  <xsl:import href="http://transpect.io/hub2html/xsl/css-atts2wrap.xsl"/>
  
  <xsl:param name="srcpaths" select="'no'"/>

  <xsl:param name="css:wrap-namespace" as="xs:string" select="''"/>
  
  <xsl:param name="dtd-version" as="xs:string" select="'2.0'" />
  
  <xsl:variable name="jats:appendix-to-bookpart" as="xs:boolean" select="false()"/>
  
  <xsl:function name="css:other-atts" as="attribute(*)*">
    <xsl:param name="context" as="element(*)"/>
    <xsl:sequence select="$context/@*[not(css:map-att-to-elt(., ..))]"/> 
  </xsl:function>

  <xsl:template name="css:remaining-atts">
    <xsl:param name="remaining-atts" as="attribute(*)*"/>
    <xsl:apply-templates select="$remaining-atts" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="@*" mode="hub2htm:css-style-overrides">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="*" mode="class-att"/>
  
  <xsl:variable name="dtd-version-att" as="attribute(dtd-version)">
    <xsl:attribute name="dtd-version" select="$dtd-version"/>
  </xsl:variable>

  <xsl:template match="* | @*" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/*" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:namespace name="css" select="'http://www.w3.org/1996/css'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:key name="by-id" match="*[@id]" use="@id"/>

  <!-- This anchor has already given its ID to someone else, but we've been
    too lazy to remove this anchor in the first run. -->
  <xsl:template match="target[if (count(root(.)/*) = 1)
                              then key('by-id', @id)/local-name() != 'target'
                              else false()
                             ]" mode="clean-up"/>
  
  <xsl:template match="sup[fn][every $c in node() satisfies $c/self::fn]" mode="clean-up">
    <!-- This has been necessitated by https://github.com/transpect/hub2html/commit/f2f09c (and parent commit). -->
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
 
  <xsl:template match="styled-content[every $att in @* satisfies $att/self::attribute(srcpath)]" mode="clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="styled-content[break]" mode="clean-up">
    <xsl:if test="break/following-sibling::node()[1][self::text()[matches(., '\S')]]">
      <xsl:apply-templates select="break" mode="#current"/>
    </xsl:if>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="node() except break" mode="#current"/>
    </xsl:copy>
    <xsl:if test="break/preceding-sibling::node()[1][self::text()[matches(., '\S')]]">
      <xsl:apply-templates select="break" mode="#current"/>
    </xsl:if>
    <xsl:message select="'WARNING: PULLED break out of styled-content'"/>
  </xsl:template>
  
  <xsl:template match="styled-content[not(node())]" mode="clean-up" priority="2"/>

  <!-- no more breaks if several paras are in head! -->
  <xsl:template match="th/p[bold][every $n in node() satisfies ($n/self::bold)]" mode="clean-up">
    <xsl:apply-templates select="bold/node()" mode="#current"/>
  </xsl:template>

  <xsl:template match="*[self::bold or self::italic][every $n in node() satisfies ($n/self::table-wrap or $n/self::target or $n/self::boxed-text)]" mode="clean-up" priority="6">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  
  <xsl:template match="th[p][count(p) eq 1][not(p/bold)]" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="css:font-weight" select="'normal'"/>
      <xsl:apply-templates select="p/node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="table[count(thead) gt 1]" mode="clean-up">
    <xsl:variable name="context" select="." as="element(table)"/>
    <xsl:for-each-group select="*" group-starting-with="thead">
      <xsl:for-each select="$context">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, current-group()" mode="#current"/>
        </xsl:copy>
      </xsl:for-each>
    </xsl:for-each-group>
  </xsl:template>
  

  <xsl:template match="body[not(following-sibling::back)][ref-list]" mode="clean-up">
    <xsl:next-match/>
    <back>
      <xsl:for-each select="ref-list">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </xsl:copy>
      </xsl:for-each>
    </back>
  </xsl:template>
  <xsl:template match="body[not(following-sibling::back)]/ref-list" mode="clean-up"/>
  
  <xsl:template match="dbk:phrase[dbk:informaltable][every $n in node() satisfies ($n/self::dbk:informaltable)]" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="p[not(parent::*[self::list-item] or self::term)][boxed-text][every $n in node() satisfies ($n/self::boxed-text)]" mode="clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <!-- not permitted by schema: -->
  <xsl:template match="sub/@content-type | sup/@content-type" mode="clean-up"/>

  <xsl:template match="*:tabs" mode="clean-up">
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>

  <!-- Preventing tabs to be eliminated without a space between -->
  <xsl:template match="*:tab" mode="clean-up">
    <xsl:choose>
      <xsl:when test="(preceding-sibling::node()[1][self::text()][matches(., '\S$')] and following-sibling::node()[1][self::text()][matches(., '^\S')]) or
                      (preceding-sibling::node()[1][matches(string-join(descendant-or-self::text(), ''), '\S$')] and following-sibling::node()[1][matches(string-join(descendant-or-self::text(), ''), '^\S')])">
        <xsl:text>&#160;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="p | title" mode="clean-up" priority="5">
    <xsl:variable name="p-atts" as="attribute(*)*" select="@*[matches(name(), '^(css:|xml:lang$)')]"/>
    <xsl:variable name="p-class-atts" as="attribute(*)*" 
      select="key(
                 'jats:style-by-type', 
                 (@style-type|@content-type), 
                 root(current())
              )/(css:attic | .)/@*[matches(name(), '^(css:|xml:lang$)')]"/>
    <xsl:next-match>
      <xsl:with-param name="p-atts" tunnel="yes" as="attribute(*)*">
        <xsl:sequence select="$p-atts, $p-class-atts[not(name() = $p-atts/name())]"/>
      </xsl:with-param>
    </xsl:next-match>
  </xsl:template>
  
  <!-- Dissolve styled content whose css atts all went to the attic.
       Will lose srcpath attributes though. Solution: Adapt the srcpath message rendering mechanism 
       so that it uses ancestor paths if it doesn’t find an immediate matching element. -->
  <xsl:template match="styled-content[@style-type]
                                     [every $att in @* satisfies (name($att) = ('style-type', 'xml:id', 'srcpath'))]"
                mode="clean-up" priority="2">
    <xsl:param name="p-atts" as="attribute(*)*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="exists($p-atts)">
        <xsl:variable name="style-atts" as="attribute(*)*"
          select="key('jats:style-by-type', @style-type, root(.))/(css:attic | .)/@*[matches(name(), '^(css:|xml:lang$)')]"/>
<!--        <xsl:if test="@srcpath = 'Stories/Story_u1645c.xml?xpath=/idPkg:Story[1]/Story[1]/ParagraphStyleRange[36]/CharacterStyleRange[2]'">
          <xsl:message select="'00 -\-\-\-\-\-\-\-\-\-\-\-', $child-element"></xsl:message>
          <xsl:message select="'22 -\-\-\-\-\-\-\-\-\-\-\-', $style-atts"></xsl:message>
        </xsl:if>-->
        <xsl:variable name="differing-attributes" select="for $a 
                                                           in $style-atts
                                                       return $a[
                                                                  some $b in $p-atts[name() = name($a)] satisfies ($b != $a)
                                                                  ]" as="attribute(*)*"/>
         <xsl:choose>
          <!-- Don’t dissolve spans if they override some para property (e.g., they make
               bold to normal by means of their style: -->
           <xsl:when test="exists($differing-attributes) and 
                           (every $child in node() satisfies name($child) != $differing-attributes)">
            <xsl:next-match/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates mode="#current">
              <xsl:with-param name="srcpath" select="@srcpath" tunnel="yes"/>
            </xsl:apply-templates>    
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="#current">
          <xsl:with-param name="srcpath" select="@srcpath" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="styled-content[matches(@style-type, $jats:cstyle-whitelist-x, 'x')]" 
    mode="clean-up" priority="4">
    <xsl:copy copy-namespaces="no">
      <xsl:copy-of select="@style-type"/>
      <xsl:apply-templates select="@* except @style-type, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:variable name="jats:cstyle-whitelist-x" as="xs:string"
    select="'(^Lit$|ch_blockade|ch_[uU]nderline)'"/>    
  
  <xsl:template match="styled-content"
                mode="clean-up" priority="3">
    <xsl:param name="root" as="document-node(element(*))" select="root()" tunnel="yes"/>
    <xsl:variable name="p" select="ancestor::*[name() = ('p', 'title')][1]" as="element(*)?"/>
    <xsl:choose>
      <!-- This condition would usually have appeared as a predicate of the matching pattern.
           Since we might process temporary trees in the adaptions, we need to be able to
           explicitly pass a root node to the key function. -->
      <xsl:when test="every $att in (key('jats:style-by-type', @style-type, $root)/(css:attic | .)/@*, @*) 
                      satisfies (
                                  name($att) = ('name', 'native-name', 'layout-type', 'srcpath', 'style-type')
                                  or 
                                  (@*[name() = name($att)], $att)[1]  = (
                                            $p/@*[name() = name($att)], 
                                            key('jats:style-by-type', $p/(@style-type|@content-type), $root)
                                              /(css:attic | .)/@*[name() = name($att)]
                                         )[1]
                                )">
        <xsl:apply-templates mode="#current">
          <xsl:with-param name="srcpath" select="@srcpath" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="styled-content/@*[matches(name(), '^(css:|xml:lang$)')]" mode="clean-up" priority="6">
    <xsl:variable name="p-att" as="attribute(*)?" select="../ancestor::*[name() = ('p', 'title')][1]/@*[name() = name(current())]"/>
    <xsl:variable name="p-style-att" as="attribute(*)*">
      <xsl:if test="count(root(..)/node()) = 1 and count(root(..)/*) = 1">
        <xsl:sequence select="key(
                                  'jats:style-by-type', 
                                  ../ancestor::*[name() = ('p', 'title')][1]/(@style-type|@content-type), 
                                  root(..)
                              )/(css:attic | .)/@*[name() = name(current())]"/>
      </xsl:if>
    </xsl:variable>
    <xsl:if test="count($p-style-att) gt 1">
      <xsl:message select="'More than one style with the same name (must not happen!) ', key(
                                  'jats:style-by-type', 
                                  ../ancestor::*[name() = ('p', 'title')][1]/(@style-type|@content-type), 
                                  root(..)
                              ), $p-style-att"/>
    </xsl:if>
    <xsl:if test="not(($p-att, $p-style-att)[1] = .)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[name() = ('italic', 'bold', 'underline')]
                        [empty(@srcpath)]
                        [empty(*[name() = ('italic', 'bold', 'underline')])]" mode="clean-up" priority="4">
    <xsl:param name="srcpath" as="attribute(srcpath)?" tunnel="yes"/>
    <xsl:copy>
      <xsl:copy-of select="$srcpath"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="italic[@css:font-style = 'normal']" mode="clean-up" priority="5">
      <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="bold[@css:font-weight = 'normal']" mode="clean-up" priority="5">
      <xsl:apply-templates mode="#current"/>
  </xsl:template>

  
  <xsl:key name="jats:style-by-type" match="css:rule" use="@name" />
  
  <xsl:template match="*" mode="default" priority="-1">
    <xsl:message>hub2bits: unhandled in mode default: <xsl:apply-templates select="." mode="css:unhandled"/>
    </xsl:message>
    <xsl:copy copy-namespaces="no">
      <xsl:call-template name="css:content"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@*" mode="default" priority="-1.5">
    <xsl:copy/>
    <xsl:message>hub2bits: attr unhandled in mode default: <xsl:apply-templates select="." mode="css:unhandled"/>
    </xsl:message>
  </xsl:template>

  <xsl:template match="mml:*/@* | @xml:space" mode="default">
    <xsl:copy/>
  </xsl:template>

  <!-- MOVE WRAP ATTS (italic, bold, underline) TO CSS RULE ATTIC -->
  
  <xsl:template match="css:rule[$css:wrap-content-with-elements-from-mappable-style-attributes]" mode="default">
     <xsl:call-template name="css:move-to-attic">
       <xsl:with-param name="atts" select="@*[css:map-att-to-elt(., key('css:styled-content', ../@name)[1])]"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="css:rule[$css:wrap-content-with-elements-from-mappable-style-attributes]
                               [not(key('css:styled-content', @name))]" mode="default" priority="2">
    <xsl:comment>
    <xsl:for-each select="@*">
      <xsl:sequence select="concat(name(), '=&quot;', ., '&quot;&#xa;')"/>
    </xsl:for-each>
    </xsl:comment>
  </xsl:template>
  
  <xsl:template match="css:rules | css:rules/@* | dbk:tabs | dbk:tab | dbk:tab/@* | dbk:linked-style | dbk:linked-style/@*" mode="default">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- DEFAULT ATTRIBUTE HANDLING -->

  <xsl:template match="@xml:id" mode="default">
    <xsl:attribute name="id" select="."/>
  </xsl:template>

  <xsl:template match="@role" mode="default">
    <xsl:param name="elt-name" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="$elt-name">
        <xsl:attribute name="book-part-type" select="."/>    
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="content-type" select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:key name="by-id" match="*[@id | @xml:id]" use="@id | @xml:id"/>
  
  <xsl:template match="@linkend | @linkends" mode="default">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="@linkend | @linkends" mode="clean-up">
    <xsl:param name="root" select="root()" as="document-node(element(*))" tunnel="yes"/>
    <xsl:variable name="targets" select="key('by-id', tokenize(., '\s+'), $root)" as="element(*)*"/>
    <xsl:variable name="types" select="jats:ref-types($targets)" as="xs:string*"/>
    <xsl:if test="count($types) eq 1">
      <xsl:attribute name="ref-type" select="$types[1]"/>
    </xsl:if>
    <xsl:attribute name="rid" select="."/>
  </xsl:template>

  <xsl:function name="jats:ref-types" as="xs:string*">
    <xsl:param name="targets" as="element(*)*"/>
    <xsl:variable name="names" select="distinct-values($targets/local-name())" as="xs:string*"/>
    <xsl:sequence select="for $n in $names return jats:ref-type($n)"/>
  </xsl:function>
  
  <xsl:function name="jats:ref-type" as="xs:string?">
    <xsl:param name="elt-name" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$elt-name eq 'app'">
        <xsl:sequence select="'app'"/>
      </xsl:when>
      <xsl:when test="$elt-name = ('ref', 'mixed-citation')">
        <xsl:sequence select="'bibr'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'boxed-text'">
        <xsl:sequence select="'boxed-text'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'disp-formula'">
        <xsl:sequence select="'disp-formula'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'fig'">
        <xsl:sequence select="'fig'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'fn'">
        <xsl:sequence select="'fn'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'sec'">
        <xsl:sequence select="'sec'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'table-wrap'">
        <xsl:sequence select="'table'"/>
      </xsl:when>
      <xsl:when test="$elt-name = ('book-part')">
        <xsl:sequence select="'book-part'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>hub2bits: unknown ref-type for <xsl:value-of select="$elt-name"/></xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="@remap | @annotations" mode="default"/>

  <xsl:template match="@css:* | css:rule/@*" mode="default">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="@xlink:href" mode="default">
    <xsl:copy/>
  </xsl:template>  
  
  <xsl:template match="@xml:lang" mode="default">
    <xsl:copy/>
  </xsl:template>  
  
  <xsl:template match="@srcpath[$srcpaths = 'yes']" mode="default" priority="2">
    <xsl:copy/>
  </xsl:template>  

  <xsl:template match="@srcpath[not($srcpaths = 'yes')]" mode="default" priority="2"/>
  
  <!-- STRUCTURE -->
  
  
  <xsl:function name="jats:matter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="name" select="$elt/local-name()" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$name = ('info', 'title', 'subtitle')"><xsl:sequence select="''"/></xsl:when>
      <xsl:when test="$name = ('toc', 'preface', 'partintro', 'acknowledgements', 'dedication')"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:colophon[@role = ('front-matter-blurb', 'frontispiz', 'copyright-page', 'title-page', 'about-contrib', 'contrib-biographies', 'quotation', 'motto')]"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:glossary[preceding-sibling::*[1][jats:matter(.) = 'front-matter'] or following-sibling::*[1][jats:matter(.)  = 'front-matter']]"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:part[jats:is-appendix-part(.)]"><xsl:sequence select="'book-back'"/></xsl:when>
      <xsl:when test="$name = ('part', 'chapter')"><xsl:sequence select="'book-body'"/></xsl:when>
      <xsl:when test="$name = ('appendix', 'index', 'glossary', 'bibliography')"><xsl:sequence select="'book-back'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'dark-matter'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="dbk:book|dbk:hub" mode="default" priority="2">
    <book xmlns:css="http://www.w3.org/1996/css" xmlns:xlink="http://www.w3.org/1999/xlink">
      <xsl:copy-of select="@css:version"/>
      <xsl:attribute name="css:rule-selection-attribute" select="'content-type style-type'"/>
      <xsl:attribute name="source-dir-uri" select="dbk:info/dbk:keywordset[@role eq 'hub']/dbk:keyword[@role eq 'source-dir-uri']"/>      
      <xsl:sequence select="$dtd-version-att"/>
      <xsl:choose>
        <xsl:when test="@xml:lang">
          <xsl:copy-of select="@xml:lang"/>
        </xsl:when>
        <xsl:when test="key('jats:style-by-type', 'NormalParagraphStyle')[@xml:lang ne '']">
          <xsl:copy-of select="key('jats:style-by-type', 'NormalParagraphStyle')/@xml:lang, @xml:lang"/>
        </xsl:when>
      </xsl:choose>
      <xsl:call-template name="matter"/>
    </book>
  </xsl:template>

  <xsl:template name="matter">
    <xsl:for-each-group select="*" group-adjacent="jats:matter(.)">
      <xsl:choose>
        <xsl:when test="current-grouping-key() ne ''">
          <xsl:element name="{current-grouping-key()}">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template match="dbk:hub/dbk:info
                      |dbk:book/dbk:info" mode="default">
    <xsl:variable name="context" select="parent::*/local-name()" as="xs:string"/>
    <xsl:variable name="elts-for-grouping" as="element()*"
                  select="dbk:title, parent::*/dbk:title, 
                          dbk:subtitle, parent::*/dbk:subtitle,
                          dbk:titleabbrev, parent::*/dbk:titleabbrev,
                          dbk:authorgroup, dbk:author, dbk:editor, 
                          (dbk:copyright|dbk:legalnotice), dbk:bibliomisc"/>
    <book-meta>
      <xsl:call-template name="title-info">
        <xsl:with-param name="elts" select="$elts-for-grouping"/>
        <xsl:with-param name="context" select="parent::*"/>
      </xsl:call-template>
      <xsl:apply-templates select="* except ($elts-for-grouping, css:rules)" mode="#current"/>
      <xsl:call-template name="custom-meta-group"/>
    </book-meta>
  </xsl:template>
  
  <!-- bring metadata elements in a valid order -->
  
  <xsl:template match="book-meta|book-part-meta|sec-meta|collection-meta" mode="clean-up">
    <xsl:copy>
      <xsl:apply-templates select="jats:order-meta(*)" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="custom-meta-group">
    <custom-meta-group>
      <xsl:apply-templates select="css:rules" mode="#current"/>
    </custom-meta-group>
  </xsl:template>
  
  <xsl:template match="dbk:biblioid" mode="default">
    <book-id>
      <xsl:apply-templates select="@class, @role, node()" mode="#current"/>
    </book-id>
  </xsl:template>
  
  <xsl:template match="dbk:biblioid[matches(@role, 'issn', 'i')]" mode="default">
    <issn>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </issn>
  </xsl:template>
  
  <xsl:template match="dbk:biblioid[matches(@role, 'isbn', 'i')]" mode="default">
    <isbn>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </isbn>
  </xsl:template>

  <xsl:template match="dbk:biblioid[not(matches(@role, '(issn|isbn)', 'i'))]/@role" mode="default">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>

  <xsl:template match="dbk:keywordset" mode="default">
    <custom-meta-group>
      <xsl:apply-templates mode="#current"/>
    </custom-meta-group>
  </xsl:template>
  
  <xsl:template match="dbk:keyword" mode="default">
    <custom-meta>
      <meta-name>
        <xsl:value-of select="@role"/>
      </meta-name>
      <meta-value>
        <xsl:value-of select="."/>
      </meta-value>
    </custom-meta>
  </xsl:template>
  
  <xsl:template match="dbk:authorgroup" mode="default">
    <contrib-group>
      <xsl:apply-templates mode="#current"/>
    </contrib-group>
  </xsl:template>
  
  <xsl:template match="dbk:author|dbk:editor" mode="default">
    <contrib contrib-type="{local-name()}">
      <xsl:call-template name="css:content"/>
    </contrib>
  </xsl:template>
  
  <xsl:template match="dbk:personname" mode="default">
    <xsl:choose>
      <xsl:when test="dbk:firstname|dbk:surname">
        <name>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:apply-templates select="dbk:surname, dbk:firstname" mode="#current"/>  
        </name>    
      </xsl:when>
      <xsl:otherwise>
        <string-name><xsl:call-template name="css:content"/></string-name>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dbk:firstname" mode="default">
    <given-names>
      <xsl:call-template name="css:content"/>  
    </given-names>
  </xsl:template>
  
  <xsl:template match="dbk:othername" mode="default">
    <string-name>
      <!-- perhaps mapped to something else? string-name is for unstructured content in contrib -->
      <xsl:apply-templates select="text()" mode="#current"/>  
    </string-name>
  </xsl:template>
  
  <xsl:template match="dbk:volumenum" mode="default">
    <book-volume-number>
      <xsl:apply-templates mode="#current"/>
    </book-volume-number>
  </xsl:template>  
  
  <xsl:template match="dbk:publisher|dbk:edition|dbk:surname" mode="default">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:publishername" mode="default">
    <publisher-name>
      <xsl:apply-templates mode="#current"/>
    </publisher-name>
  </xsl:template>
  
  <xsl:template match="dbk:publisher/dbk:address" mode="default">
    <publisher-loc>
      <xsl:apply-templates mode="#current"/>
    </publisher-loc>
  </xsl:template>
  
  <xsl:template match="dbk:copyright" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:copyright/dbk:year" mode="default">
    <copyright-year>
      <xsl:apply-templates mode="#current"/>  
    </copyright-year>
  </xsl:template>
  
  <xsl:template match="dbk:copyright/dbk:holder" mode="default">
    <copyright-holder>
      <xsl:apply-templates mode="#current"/>
    </copyright-holder>
  </xsl:template>
  
  <xsl:template match="dbk:legalnotice" mode="default">
    <copyright-statement>
      <xsl:apply-templates mode="#current"/>
    </copyright-statement>
  </xsl:template>
  
 <!--  TO-DO!-->
    
  <xsl:template match="dbk:org" mode="default" priority="2">
    <institution><xsl:apply-templates select="@*, node()[self::text() | self::dbk:orgname]" mode="#current"/></institution>
    <xsl:apply-templates select="* except dbk:orgname" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:orgname" mode="default" priority="2">
    <xsl:apply-templates select="@*, node()" mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:affiliation" mode="default" priority="2">
    <aff>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </aff>
  </xsl:template>
  
  <xsl:template match="dbk:personblurb" mode="default" priority="2">
    <bio>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </bio>
  </xsl:template>
  
  <xsl:template match="dbk:pubdate" mode="default">
    <pub-date>
      <xsl:if test=". castable as xs:date">
        <xsl:attribute name="iso-8601-date" select="xs:date(.)"/>
      </xsl:if>
      <string-date>
        <xsl:apply-templates mode="#current"/>
      </string-date>
    </pub-date>
  </xsl:template>
  
  <xsl:template match="dbk:toc" mode="default">
    <toc>
      <xsl:apply-templates select="." mode="toc-depth"/>
      <xsl:call-template name="css:content"/>
    </toc>
  </xsl:template>

  <xsl:template match="dbk:toc/dbk:title | dbk:index/dbk:title" mode="default" priority="2">
    <title-group>
      <xsl:next-match/>
    </title-group>
  </xsl:template>
  
  <xsl:template match="dbk:toc" mode="toc-depth">
    <xsl:attribute name="depth" select="'3'"/>
  </xsl:template>

  <xsl:template match="dbk:section" mode="default">
    <sec><xsl:call-template name="css:content"/></sec>
  </xsl:template>
  
  <xsl:template match="@renderas" mode="default">
    <xsl:attribute name="disp-level" select="."/>
  </xsl:template>

  <xsl:template match="dbk:appendix" mode="default">
    <app>
      <!-- why is that done???-->
      <xsl:apply-templates select="@*, * except dbk:info, dbk:info" mode="#current"/>
    </app>
  </xsl:template>

  <xsl:template match="dbk:acknowledgements | dbk:preface[@role = 'acknowledgements']" mode="default">
    <ack><xsl:call-template name="css:content"/></ack>
  </xsl:template>
  
  <xsl:template match="dbk:preface[@role = 'acknowledgements']/@role" mode="default" priority="2"/>

  <xsl:template match="dbk:glossary" mode="default">
    <xsl:choose>
      <xsl:when test="ancestor::*/self::dbk:part[jats:is-appendix-part(.)]">
        <app>
          <glossary>
            <xsl:apply-templates select="@*, * except dbk:info, dbk:info" mode="#current"/>
          </glossary>
        </app>
      </xsl:when>
      <xsl:otherwise>
        <glossary>
          <xsl:apply-templates select="@*, * except dbk:info, dbk:info" mode="#current"/>
        </glossary>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  
  <xsl:template match="dbk:index" mode="default">
    <index>
      <xsl:apply-templates select="@*, dbk:title" mode="#current"/>
      <!-- will be filled in clean-up -->
    </index>
  </xsl:template>

  <xsl:function name="jats:book-part" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:part[jats:is-appendix-part(.)]"><xsl:sequence select="'app-group'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:part or $elt/self::dbk:chapter"><xsl:sequence select="'book-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:partintro
                    | $elt/self::dbk:colophon[@role = ('front-matter-blurb', 'title-page', 'copyright-page', 'frontispiz', 'about-contrib', 'contrib-biographies', 'motto', 'quotation')]"><xsl:sequence select="'front-matter-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'foreword')]"><xsl:sequence select="'foreword'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'acknowledgements')]"><xsl:sequence select="'ack'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'praise')]"><xsl:sequence select="'front-matter-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface"><xsl:sequence select="'preface'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:dedication"><xsl:sequence select="'dedication'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:acknowledgements"><xsl:sequence select="'ack'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:glossary"><xsl:sequence select="'glossary'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:index"><xsl:sequence select="'index'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'unknown-book-part'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="jats:is-appendix-part" as="xs:boolean">
    <xsl:param name="elt" as="element(dbk:part)"/>
    <xsl:sequence select="if ($jats:appendix-to-bookpart) then false() else (every $c in $elt/* satisfies $c/name() = ('appendix', 'index', 'bibliography', 'glossary', 'title', 'subtitle', 'info'))"/>
  </xsl:function>

  <xsl:function name="jats:book-part-body" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:part or $elt/self::dbk:chapter"><xsl:sequence select="'body'"/></xsl:when>
      <xsl:when test="local-name($elt) = ('preface', 'partintro', 'dedication', 'preface', 'colophon')"><xsl:sequence select="'named-book-part-body'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="concat('unknown-book-part-body_', $elt/name())"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:variable name="jats:additional-backmatter-parts-title-role-regex" as="xs:string" select="'(p_h_sec[12]_back)'"/>

  <xsl:function name="jats:part-submatter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="name($elt) = ('title', 'info', 'subtitle', 'titleabbrev')">
        <xsl:sequence select="'book-part-meta'"/>
      </xsl:when>
      <xsl:when test="name($elt) = ('toc')">
        <xsl:sequence select="'front-matter'"/>
      </xsl:when>
      <xsl:when test="name($elt) = ('bibliography', 'glossary', 'appendix', 'index')">
        <xsl:sequence select="'back'"/>
      </xsl:when>
      <xsl:when test="name($elt) = 'section' and $elt[matches(dbk:title/@role, $jats:additional-backmatter-parts-title-role-regex)]">
        <xsl:sequence select="'back'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="jats:book-part-body($elt/..)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="jats:order-meta" as="element()+">
    <xsl:param name="seq" as="element()+"/>
    <xsl:for-each select="$seq">
      <xsl:sort select="jats:get-meta-order-int(.)"/>
      <xsl:sequence select="."/>
    </xsl:for-each>
  </xsl:function>
  
  <xsl:function name="jats:get-meta-order-int" as="xs:integer">
    <xsl:param name="elt" as="element()"/>
    <xsl:value-of select="if($elt/self::book-id)                                                    then  1
                     else if($elt/self::subj-group)                                                 then  2
                     else if($elt/self::book-title-group or $elt/self::title-group)                 then  3
                     else if($elt/local-name() = ('contrib-group', 'aff', 'aff-alternatives', 'x')) then  4
                     else if($elt/self::author-notes)                                               then  5
                     else if($elt/self::pub-date)                                                   then  6
                     else if($elt/self::book-volume-number)                                         then  7
                     else if($elt/self::book-volume-id)                                             then  8
                     else if($elt/self::issn)                                                       then  9
                     else if($elt/self::issn-1)                                                     then 10
                     else if($elt/self::isbn)                                                       then 11
                     else if($elt/self::publisher)                                                  then 12
                     else if($elt/self::edition)                                                    then 13
                     else if($elt/self::supplementary-material)                                     then 14
                     else if($elt/self::pub-history)                                                then 15
                     else if($elt/self::permissions)                                                then 16
                     else if($elt/self::self-uri)                                                   then 17
                     else if($elt/local-name() = ('related-article', 'related-object'))             then 18
                     else if($elt/self::abstract)                                                   then 19
                     else if($elt/self::trans-abstract)                                             then 20
                     else if($elt/self::kwd-group)                                                  then 21
                     else if($elt/self::funding-group)                                              then 22
                     else if($elt/self::conference)                                                 then 23
                     else if($elt/self::counts)                                                     then 24
                     else if($elt/self::custom-meta-group)                                          then 25
                     else if($elt/self::notes)                                                      then 26
                     else                                                                               100"/>
  </xsl:function> 
  
  <xsl:template match="dbk:part[jats:is-appendix-part(.)]" mode="default">
    <app-group>
      <xsl:call-template name="css:content"/>
    </app-group>
  </xsl:template>
  
  <xsl:template match="app-group" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node() except (ref-list | index)" mode="#current"/>
    </xsl:copy>
    <xsl:apply-templates select="ref-list | index" mode="#current"/>
  </xsl:template>
  
  
  <xsl:template match="  dbk:part | dbk:chapter | dbk:preface[not(@role = 'acknowledgements')] 
                       | dbk:partintro | dbk:colophon | dbk:dedication" mode="default">
    <xsl:variable name="elt-name" as="xs:string" select="jats:book-part(.)"/>
    <xsl:element name="{$elt-name}">
      <xsl:apply-templates select="@*" mode="#current">
        <xsl:with-param name="elt-name" select="$elt-name"/>
      </xsl:apply-templates>
      <xsl:if test="$elt-name eq 'book-part'">
        <xsl:attribute name="book-part-type" select="local-name()"/>
      </xsl:if>
      <xsl:variable name="context" select="." as="element(*)"/>
      <xsl:for-each-group select="*" group-adjacent="jats:part-submatter(.)">
        <xsl:element name="{current-grouping-key()}">
          <xsl:choose>
            <xsl:when test="matches(current-grouping-key(), 'meta')">
              <xsl:call-template name="title-info">
                <xsl:with-param name="elts" 
                                select="current-group()/(self::dbk:title|self::dbk:info/*|self::dbk:subtitle|self::dbk:titleabbrev)"/>
                <xsl:with-param name="context" select="parent::*"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:element>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@renderas[not(parent::dbk:section)]" mode="default"/>
    
  <xsl:template match="dbk:preface/@role" mode="default">
    <xsl:attribute name="book-part-type" select="."/>
  </xsl:template>
  
  <!-- METADATA -->

  <xsl:function name="jats:meta-component" as="xs:string+">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:param name="context" as="element()?"/>
    <xsl:value-of select="if($elt/self::dbk:title or $elt/self::dbk:subtitle or $elt/self::dbk:titleabbrev)
                            then (if($context/self::dbk:book or $context/self::dbk:hub) then 'book-title-group' else 'title-group')
                     else if($elt/self::dbk:authorgroup or $elt/self::dbk:author or $elt/self::dbk:editor)
                            then 'contrib-group'
                     else if($elt/self::dbk:abstract)
                            then 'abstract'
                     else if($elt/self::dbk:legalnotice or $elt/self::dbk:copyright)
                            then 'permissions'
                     else if($elt/self::dbk:bibliomisc)
                            then 'custom-meta-group'
                     else        concat('unknown-meta_', $elt/name())"/>
  </xsl:function>

  <xsl:template name="title-info" as="element(*)*">
    <xsl:param name="elts" as="element(*)*"/>
    <xsl:param name="context" as="element()?"/>
    <xsl:for-each-group select="$elts" group-by="jats:meta-component(., $context)">
      <xsl:choose>
        <xsl:when test="current-grouping-key() = 'abstract'">
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="{current-grouping-key()}" namespace="">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="dbk:info" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:section/dbk:info[dbk:title][count(*) gt 1]" mode="default" priority="2">
    <sec-meta>
      <xsl:apply-templates select="dbk:authorgroup, dbk:author" mode="#current"/>
    </sec-meta>
    <xsl:apply-templates select="dbk:title, dbk:subtitle, dbk:titleabbrev" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:section/dbk:info/dbk:author" mode="default" priority="3">
    <contrib-group>
      <xsl:next-match/>
    </contrib-group>
  </xsl:template>
  
  <xsl:template match="dbk:book/dbk:title|dbk:book/dbk:info/dbk:title" mode="default">
    <book-title>
   <xsl:apply-templates  select="@xml:id, @xml:base, node()" mode="#current"/>
    </book-title>
  </xsl:template> 
   
  <xsl:template match="dbk:subtitle" mode="default">
    <subtitle>
      <xsl:call-template name="css:content"/>
    </subtitle>
  </xsl:template>
  
  <xsl:template match="dbk:titleabbrev" mode="default">
    <alt-title>
      <xsl:call-template name="css:content"/>
    </alt-title>
  </xsl:template>
  
  <xsl:template match="dbk:subtitle/dbk:date" mode="default">
    <named-content content-type="edition">
      <xsl:call-template name="css:content"/>
    </named-content>
  </xsl:template> 
  
  <xsl:template match="dbk:abstract" mode="default">
    <abstract>
      <xsl:call-template name="css:content"/>
    </abstract>
  </xsl:template>
  
  <!-- BLOCK -->
 
  <xsl:template match="dbk:title" mode="default">
    <title>
      <xsl:call-template name="css:content"/>
    </title>
  </xsl:template>

  <!-- Don’t wrap title content in a bold element -->
  <xsl:template match="@css:font-weight[matches(., '^bold|[6-9]00$')]" mode="css:map-att-to-elt" as="xs:string?">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:if test="not(
                    $context/local-name() = ('title', 'subtitle', 'alt-title')
                    or
                    ($context/local-name() = ('phrase') and $context/../local-name() = ('title', 'subtitle', 'alt-title')) 
                  )">
      <xsl:sequence select="$css:bold-elt-name"/>  
    </xsl:if>
  </xsl:template>
  

  <xsl:template match="dbk:title[dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')]]" mode="default">
    <xsl:variable name="identifier" select="dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')][1]" as="element(dbk:phrase)"/>
    <label>
      <xsl:apply-templates select="dbk:anchor[matches(@xml:id, '^(cell)?page_')][. &lt;&lt; $identifier]" mode="#current"/>
      <xsl:apply-templates mode="#current" select="$identifier/node()"/>
    </label>
    <title>
      <xsl:apply-templates mode="#current"
        select="@*, node() except ($identifier | dbk:tab | dbk:anchor[matches(@xml:id, '^(cell)?page_')][. &lt;&lt; $identifier])"/>
    </title>
  </xsl:template>

  <xsl:template match="dbk:para | dbk:simpara" mode="default">
    <p><xsl:call-template name="css:content"/></p>
  </xsl:template>
  
  <xsl:template match="dbk:blockquote" mode="default">
    <disp-quote><xsl:call-template name="css:content"/></disp-quote>
  </xsl:template>
  
  <!-- INLINE -->
  
  <xsl:variable name="css:italic-elt-name" as="xs:string" select="'italic'"/>
  <xsl:variable name="css:bold-elt-name" as="xs:string" select="'bold'"/>
  <xsl:variable name="css:underline-elt-name" as="xs:string?" select="'underline'"/>
  
  <xsl:template match="dbk:phrase" mode="default">
    <styled-content><xsl:call-template name="css:content"/></styled-content>
  </xsl:template>

  <xsl:template match="dbk:phrase/@role" mode="default">
    <xsl:attribute name="style-type" select="."/>
  </xsl:template>

  <xsl:template match="dbk:link[@linkend, @linkends]" mode="default">
    <xref><xsl:call-template name="css:content"/></xref>
  </xsl:template>
  
  <xsl:template match="dbk:link[@xlink:href]|dbk:ulink[@url]" mode="default">
    <ext-link><xsl:call-template name="css:content"/></ext-link>
  </xsl:template>
  
  <xsl:template match="dbk:ulink/@url" mode="default">
    <xsl:attribute name="ext-link-type" select="'uri'"/>
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:ulink/@hub:*"/>

  <xsl:template match="dbk:xref[@linkend]" mode="default">
    <xref rid="{@linkend}"/>
  </xsl:template>

  <xsl:template match="dbk:anchor" mode="default">
    <target>
      <xsl:call-template name="css:content"/>
    </target>
  </xsl:template>
  
  <xsl:template match="dbk:anchor/@role" mode="default">
    <xsl:attribute name="target-type" select="."/>
  </xsl:template>

  <xsl:template match="boxed-text/target | boxed-text/sec/target | boxed-text/sec/sec/target" mode="clean-up">
    <p>
      <xsl:next-match/>
    </p>
  </xsl:template>
  
  <xsl:template match="dbk:br" mode="default">
    <break/>
  </xsl:template>
  
  <xsl:template match="dbk:superscript" mode="default">
    <sup>
      <xsl:call-template name="css:content"/>
    </sup>
  </xsl:template>
  
  <xsl:template match="dbk:subscript" mode="default">
    <sub>
      <xsl:call-template name="css:content"/>
    </sub>
  </xsl:template>
  
  <xsl:variable name="jats:speech-para-regex" as="xs:string" select="'letex_speech'"/>
  <xsl:variable name="jats:speaker-regex" as="xs:string" select="'letex_speaker'"/>
  
  <xsl:template match="dbk:para[matches(@role, $jats:speech-para-regex)]" mode="default" priority="4">
    <speech>
      <xsl:if test="exists(descendant::dbk:phrase[matches(@role,  $jats:speaker-regex)]) or matches(., '^[\S]+?:.*\S+')">
      <speaker>
        <xsl:choose>
          <xsl:when test="dbk:phrase[matches(@role, $jats:speaker-regex)] or dbk:phrase/dbk:phrase[matches(@role, $jats:speaker-regex)]">
            <xsl:apply-templates select="descendant::dbk:phrase[@role][matches(@role, $jats:speaker-regex)]/@* except descendant::dbk:phrase[matches(@role, $jats:speaker-regex)]/@role" mode="#current"/>
            <xsl:if test="descendant::dbk:phrase[@role][matches(@role, $jats:speaker-regex)]">
              <xsl:attribute name="content-type" select="descendant::dbk:phrase[@role][matches(@role, $jats:speaker-regex)]/@role"/>
            </xsl:if>
            <xsl:apply-templates select="(dbk:phrase[@role][matches(@role, $jats:speaker-regex)], dbk:phrase[dbk:phrase[@role][matches(@role, $jats:speaker-regex)]])[1]/node()" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="replace(., '^([\S]+?:)(.+)$', '$1', 's')"/>
          </xsl:otherwise>
        </xsl:choose>
      </speaker>
      </xsl:if>
      <p>
        <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:choose>
          <xsl:when test="exists(descendant::dbk:phrase[matches(@role,  $jats:speaker-regex)])">
            <xsl:apply-templates select="node() except (dbk:phrase[matches(@role, $jats:speaker-regex)], dbk:phrase[dbk:phrase[matches(@role, $jats:speaker-regex)]], dbk:tab)" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- the speaker has to be eliminated in next mode -->
            <xsl:apply-templates select="node()" mode="#current">
              <xsl:with-param name="discard" as="xs:boolean" tunnel="yes" select="true()"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </p>
    </speech>  
  </xsl:template>
  
  <xsl:template match="dbk:phrase[matches(@role, $jats:speaker-regex)]" mode="default">
    <xsl:param name="discard" tunnel="yes" as="xs:boolean?"/>
    <xsl:if test="not($discard)">
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="speaker/@content-type" mode="clean-up" priority="2"/>
  
  <xsl:template match="text()[(ancestor::*[self::p])[1]/preceding-sibling::*[1][self::speaker[not(@content-type)]]][matches(., '^[\S]+?:', 's')]" mode="clean-up">
    <xsl:if test="(ancestor::*[self::p])[1]/preceding-sibling::*[1][self::speaker[matches(., '^[\S]+?:', 's')]]">
      <xsl:value-of select="replace(., '^([\S]+?:)\p{Zs}*(.+)$', '$2', 's')"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*[speech]" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*" group-starting-with="speech[speaker]">
        <xsl:variable name="context" select="current-group()"/>
        <xsl:choose>
          <xsl:when test="current-group()[self::speech]">
            <xsl:for-each-group select="current-group()" group-ending-with="speech[jats:is-speech-end(.)]">
              <xsl:choose>
                <xsl:when test="current-group()[self::speech]">
                  <speech>
                    <xsl:apply-templates select="current-group()/node()" mode="#current"/>
                  </speech>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:for-each select="current-group()">
                    <xsl:apply-templates select="." mode="#current"/>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each-group>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
    
    <xsl:function name="jats:is-speech-end" as="xs:boolean">
      <xsl:param name="context" as="element(*)*"/>
      <xsl:choose>
        <xsl:when test="$context[self::speech][following-sibling::*[1][not(self::speech)]]">
          <xsl:sequence select="true()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
  
  
  <!-- INDEXTERMS -->
  
  <xsl:template match="dbk:indexterm" mode="default">
    <index-term>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="dbk:primary" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <!-- not supported in JATS -->
  <xsl:template match="dbk:indexterm/@pagenum" mode="default"/>
    
  <xsl:template match="dbk:primary" mode="default">
    <xsl:apply-templates select="@sortas" mode="#current"/>
    <term>
      <xsl:apply-templates select="node() except (dbk:see, dbk:seealso)" mode="#current"/>
    </term>
    <xsl:apply-templates select="if(../dbk:secondary) then ../dbk:secondary 
                                 else ( ../dbk:see union ../dbk:seealso union dbk:see union dbk:seealso)" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:secondary" mode="default">
    <index-term>
      <xsl:apply-templates select="@sortas" mode="#current"/>
      <term>
        <xsl:apply-templates select="node() except ( dbk:see, dbk:seealso)" mode="#current"/>
      </term>
      <xsl:apply-templates select="if(../dbk:tertiary) then ../dbk:tertiary else ( dbk:see | dbk:seealso)" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:tertiary" mode="default">
    <index-term>
      <xsl:apply-templates select="@sortas" mode="#current"/>
      <term>
        <xsl:apply-templates select="node() except (dbk:see, dbk:seealso)" mode="#current"/>
      </term>
      <xsl:apply-templates select="dbk:see | dbk:seealso" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:see" mode="default">
    <see>
      <xsl:call-template name="css:content"/>
    </see>
  </xsl:template>
  
  <xsl:template match="dbk:seealso" mode="default">
    <see-also>
      <xsl:call-template name="css:content"/>
    </see-also>
  </xsl:template>

  <xsl:template match="@sortas" mode="default">
    <xsl:attribute name="sort-key" select="."/>
  </xsl:template>

  <!-- FOOTNOTES -->
  
  <xsl:template match="dbk:footnote" mode="default">
    <xsl:variable name="label" select="dbk:para[1]/*[1][self::dbk:phrase][@role eq 'hub:identifier']" as="element(dbk:phrase)?"/>
    <fn>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$label">
        <label>
          <xsl:apply-templates select="$label" mode="fn-label"/>
        </label>  
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </fn>
  </xsl:template>
  
  <xsl:template match="dbk:footnote/dbk:para[1]/node()[1][self::dbk:phrase][@role eq 'hub:identifier']" mode="fn-label">
    <xsl:apply-templates mode="default"/>
  </xsl:template>
  
  <xsl:template match="dbk:footnote/dbk:para[1]/node()[1][self::dbk:phrase][@role eq 'hub:identifier']" mode="default"/>
  
  <!-- LISTS -->
  
  <xsl:template match="dbk:orderedlist" mode="default">
    <list list-type="order">
      <xsl:attribute name="id" select="generate-id()"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </list>
  </xsl:template>
  
  <xsl:template match="dbk:itemizedlist" mode="default">
    <list list-type="bullet">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </list>
  </xsl:template>
  
  <xsl:template match="dbk:variablelist" mode="default">
    <def-list>
      <xsl:attribute name="id" select="generate-id()"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def-list>
  </xsl:template>
  
  <xsl:template match="dbk:varlistentry" mode="default">
    <def-item>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def-item>
  </xsl:template>

  <xsl:template match="dbk:varlistentry/dbk:term" mode="default">
    <term>
      <xsl:call-template name="css:content"/>
    </term>
  </xsl:template>
  
	<xsl:template match="dbk:variablelist[ancestor::*[self::dbk:variablelist]] | dbk:itemizedlist[ancestor::*[self::dbk:variablelist]] | dbk:orderedlist[ancestor::*[self::dbk:variablelist]]" mode="default" priority="5">
    <!-- special case: ordered or itemized lists in definition lists have to become also a def-list otherwise it is invalid hobots-->
    <p specific-use="{name()}">
      <def-list>
        <xsl:attribute name="id" select="generate-id()"/>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </def-list>
    </p>
  </xsl:template>
  
  <xsl:template match="dbk:orderedlist[ancestor::*[self::dbk:variablelist]]/dbk:listitem | dbk:itemizedlist[ancestor::*[self::dbk:variablelist]]/dbk:listitem" mode="default" priority="5">
    <def-item>
      <xsl:apply-templates select="@* except(@override)" mode="#current"/>
      <xsl:element name="term">
        <xsl:value-of select="if (@override) then @override else ../@mark"/>
      </xsl:element>
      <def>
        <xsl:apply-templates select="node()" mode="#current"/>
      </def>
    </def-item>
  </xsl:template>
   
  <xsl:template match="dbk:varlistentry/dbk:listitem" mode="default">
    <def>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def>
  </xsl:template>
  
  <xsl:template match="@numeration" mode="default">
    <xsl:choose>
      <xsl:when test=". = 'arabic'"><xsl:attribute name="list-type" select="'order'"/></xsl:when>
      <xsl:when test=". = 'upperalpha'"><xsl:attribute name="list-type" select="'alpha-upper'"/></xsl:when> 
      <xsl:when test=". = 'loweralpha'"><xsl:attribute name="list-type" select="'alpha-lower'"/></xsl:when>
      <xsl:when test=". = 'upperroman'"><xsl:attribute name="list-type" select="'roman-upper'"/></xsl:when> 
      <xsl:when test=". = 'lowerroman'"><xsl:attribute name="list-type" select="'roman-lower'"/></xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@continuation[. = 'continues']" mode="default">
    <xsl:variable name="preceding-list" select="../preceding-sibling::dbk:orderedlist[1]" as="element(dbk:orderedlist)?"/>
    <xsl:attribute name="continued-from" select="$preceding-list/(@xml:id, generate-id())[1]"/>    
    <xsl:if test="not($preceding-list)">
      <xsl:message>hub2bits: No list to continue found. Look for an empty continued-from attribute in the output.</xsl:message>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="@startingnumber" mode="default">
    <xsl:message>hub2bits: No startingnumber support in BITS. Attribute copied nonetheless.</xsl:message>
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="dbk:listitem" mode="default">
    <list-item>
      <xsl:apply-templates select="@* except @override, @override, node()" mode="#current"/>
    </list-item>
  </xsl:template>
  
  <xsl:template match="dbk:listitem/@override" mode="default">
    <label>
      <xsl:value-of select="."/>
    </label>
  </xsl:template>
  
  <xsl:template match="dbk:listitem/dbk:figure" mode="default">
    <p>
      <xsl:next-match/>
    </p>
  </xsl:template>
  
  <xsl:template match="dbk:itemizedlist/@mark" mode="default">
    <xsl:variable name="type" as="xs:string?">
      <xsl:choose>
        <xsl:when test=". = '&#x25fd;'"><xsl:value-of select="'box'"/></xsl:when>
        <xsl:when test=". = '&#x2713;'"><xsl:value-of select="'check'"/></xsl:when>
        <xsl:when test=". = '&#x25e6;'"><xsl:value-of select="'circle'"/></xsl:when>
        <xsl:when test=". = '&#x25c6;'"><xsl:value-of select="'diamond'"/></xsl:when>
        <xsl:when test=". = '&#x2022;'"><xsl:value-of select="'disc'"/></xsl:when>
        <xsl:when test=". = ('&#x2013;', '&#x2014;')"><xsl:value-of select="'hyphen'"/></xsl:when>
        <xsl:when test=". = '&#x25fe;'"><xsl:value-of select="'square'"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$type">
      <xsl:attribute name="css:list-style-type" select="$type"/>  
    </xsl:if>
  </xsl:template>
  
  <!-- BOXES -->
  
  <xsl:function name="jats:box-type" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:apply-templates select="$elt" mode="box-type"/>
  </xsl:function>

  <!-- override these templates in your customization so that there remains a single text node
       that gives the box type -->
  
  <xsl:template match="*" mode="box-type">
    <xsl:apply-templates select="@*, *" mode="#current"/>
  </xsl:template>

  <xsl:template match="@*" mode="box-type"/>
  
  <xsl:template match="dbk:sidebar[@remap eq 'Group']" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  
  <xsl:template match="dbk:sidebar" mode="default">
    <boxed-text>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </boxed-text>
  </xsl:template>
  
  <!-- POETRY -->
  
  <xsl:template match="dbk:poetry | dbk:poetry/dbk:linegroup | dbk:linegroup[not(parent::dbk:poetry)] " mode="default">
    <verse-group>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </verse-group>
  </xsl:template>
  
  <xsl:template match="dbk:linegroup/dbk:line" mode="default">
    <verse-line>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </verse-line>
  </xsl:template>
  
  
  <!-- FIGURES -->
  
  <xsl:template match="dbk:figure" mode="default">
    <fig>
      <xsl:call-template name="css:other-atts"/>
      <xsl:apply-templates select="(.//dbk:anchor[not(matches(@xml:id, '^(cell)?page_'))])[1]/@xml:id" mode="#current"/>
      <label>
        <xsl:apply-templates select=".//*:anchor[matches(@xml:id, '^(cell)?page_')][1]" mode="#current"/>
        <xsl:apply-templates mode="#current" select="dbk:title/dbk:phrase[@role eq 'hub:caption-number']"/>
      </label>
      <caption>
        <title>
          <xsl:apply-templates mode="#current"
            select="dbk:title/(@* | node() except (dbk:phrase[@role eq 'hub:caption-number'] | dbk:tab | *:anchor[matches(@xml:id, '^(cell)?page_')][1]))"/>
        </title>
         <xsl:if test="dbk:caption">
          <xsl:apply-templates select="dbk:caption/dbk:para" mode="#current"/>
        </xsl:if>
        <xsl:if test="dbk:note">
          <xsl:apply-templates select="dbk:note/dbk:para" mode="#current"/>
        </xsl:if>
      </caption>
      <xsl:apply-templates select="* except (dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']] | dbk:note | dbk:caption)" mode="#current"/>
      <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
    </fig>
  </xsl:template>
  
  <xsl:template match="dbk:figure/@role" mode="default">
    <xsl:attribute name="fig-type" select="."/>
  </xsl:template>
  
  <xsl:template match="fig[target]" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="not(@id)">
        <xsl:attribute name="id" select="target/@id"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="#current">
          <xsl:with-param name="move-floating-target-in-fig-to-caption" select="if (@id) then true() else false()" as="xs:boolean" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="fig/target" mode="clean-up"/>
  
  <xsl:template match="fig/label" mode="clean-up">
    <xsl:param name="move-floating-target-in-fig-to-caption" as="xs:boolean?" tunnel="yes"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:if test="$move-floating-target-in-fig-to-caption">
        <xsl:copy-of select="../target"/>
      </xsl:if>
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="dbk:figure/dbk:note" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  
<!--  <xsl:template match="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="default">
    <permissions>
      <xsl:apply-templates mode="#current"/>
    </permissions>
  </xsl:template>-->
  
  <xsl:template match="dbk:info/dbk:legalnotice[@role eq 'copyright']" mode="default">
      <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:info/dbk:legalnotice[@role eq 'copyright']/dbk:para" mode="default">
    <copyright-statement>
      <xsl:apply-templates select="@* except @role, node()" mode="#current"/>
    </copyright-statement>
  </xsl:template>
  
  <xsl:template match="dbk:mediaobject | dbk:inlinemediaobject | dbk:imageobject" mode="default">
    <xsl:if test="@xml:id">
      <target id="{@xml:id}"/>
    </xsl:if>
    <xsl:apply-templates select="node() except dbk:alt" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:imagedata" mode="default">
    <xsl:element name="{if ( 
                             not(name(../../..) = ('figure', 'entry', 'colophon', 'table', 'alt'))
                             or
                             name(../..) = 'inlinemediaobject' 
                             )
                        then 'inline-graphic' 
                        else 'graphic'}">
      <xsl:apply-templates select="(ancestor::dbk:mediaobject | ancestor::dbk:inlinemediaobject)[1]/@xml:id" mode="#current"/>
      <xsl:call-template name="css:content"/>
      <xsl:apply-templates select="(ancestor::dbk:mediaobject | ancestor::dbk:inlinemediaobject)[1]/dbk:alt" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:alt" mode="default">
    <alt-text><xsl:apply-templates mode="#current"/></alt-text>
  </xsl:template>

  <!-- Override in adaptions -->
  <xsl:template match="dbk:imagedata/@fileref" mode="default">
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>
  
  <!-- TABLES -->
  
  <!-- todo: group with table footnotes -->
    
  <xsl:template match="dbk:row" mode="default">
    <tr>
      <xsl:call-template name="css:content"/>
    </tr>
  </xsl:template>
  
  <xsl:template match="dbk:tgroup" mode="default">
    <xsl:choose>
      <xsl:when test="dbk:colspec">
        <colgroup>
          <xsl:apply-templates select="dbk:colspec" mode="#current"/>
        </colgroup>
        <xsl:apply-templates select="node() except dbk:colspec" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="css:content"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dbk:tgroup/@cols" mode="default"/>
  
  <xsl:template match="dbk:tbody" mode="default">
    <tbody>
      <xsl:call-template name="css:content"/>
    </tbody>
  </xsl:template>

  <xsl:template match="dbk:colspec[@colwidth]" mode="default">
    <col>
      <xsl:apply-templates select="@colwidth" mode="#current"/>
    </col>
  </xsl:template>
  
  <xsl:template match="dbk:colspec/@colwidth" mode="default">
    <xsl:attribute name="width" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:table/@css:width | dbk:informaltable/@css:width" mode="default" priority="2">
    <xsl:attribute name="{local-name()}" select="."/>
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="dbk:thead" mode="default">
    <thead>
      <xsl:call-template name="css:content"/>
    </thead>
  </xsl:template>
  
  <xsl:template match="dbk:entry" mode="default">
    <xsl:element name="{if (ancestor::dbk:thead) then 'th' else 'td'}">
      <xsl:call-template name="css:content"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:entry/@namest" mode="default">
    <xsl:attribute name="colspan" select="number(replace(../@nameend, 'c(ol)?', '')) - number(replace(., 'c(ol)?', '')) + 1"/>
  </xsl:template>
  
  <xsl:template match="dbk:entry/@morerows" mode="default">
    <xsl:if test="xs:integer(.) ge 1">
      <xsl:attribute name="rowspan" select=". + 1"/>
    </xsl:if>
  </xsl:template>
  
   <xsl:template match="dbk:table/dbk:title" name="dbk:table-title" mode="default" priority="2">
     <xsl:if test="dbk:phrase[@role eq 'hub:caption-number']">
       <label>
         <xsl:apply-templates select="dbk:anchor[matches(@xml:id, '^(cell)?page_')][1]" mode="#current"/>
         <xsl:apply-templates mode="#current" select="dbk:phrase[@role eq 'hub:caption-number']"/>
       </label>
       </xsl:if>
     <xsl:if test=".//text() or ../dbk:caption">
       <caption>
         <xsl:if test=".//text()">
         <title>
           <xsl:apply-templates mode="#current"
             select="@* | node() except (dbk:phrase[@role eq 'hub:caption-number'] | dbk:tab | dbk:anchor[matches(@xml:id, '^(cell)?page_')][1])"/>
         </title>
         </xsl:if>
       <xsl:if test="../dbk:caption">
           <xsl:apply-templates select="../dbk:caption/dbk:note/dbk:para, ../dbk:caption/dbk:para" mode="#current"/>
         </xsl:if>
       </caption>
       </xsl:if>
   </xsl:template>
  
  <xsl:template match="dbk:textobject | dbk:caption | dbk:note" mode="default"/>
  
  <xsl:template match="dbk:caption//dbk:para | dbk:textobject/dbk:para" mode="default">
    <p>
      <xsl:call-template name="css:content"/>
    </p>
  </xsl:template>  
  
  <xsl:template match="dbk:informaltable | dbk:table" mode="default">
    <xsl:if test="dbk:textobject[every $elt in node() satisfies $elt/self::dbk:sidebar]">
      <xsl:apply-templates select="dbk:textobject/node()" mode="#current"/>
    </xsl:if>
    <table-wrap>
      <xsl:apply-templates select="@* except (@role | @css:*), dbk:title" mode="#current"/>
      <xsl:choose>
        <xsl:when test="exists(dbk:mediaobject) and not(dbk:tgroup)">
          <xsl:apply-templates select="* except (dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']])" mode="#current"/>
          <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
        </xsl:when>
        <xsl:when test="exists(dbk:tgroup/*/dbk:row)">
          <!-- if there is an alternative image (additional to the real table) -->
          <xsl:apply-templates select="dbk:alt" mode="#current"/>
          <xsl:for-each select="dbk:tgroup">
            <table>
              <xsl:apply-templates select="../@role | ../@css:*" mode="#current"/>
              <xsl:apply-templates select="." mode="#current"/>
              <!--<xsl:apply-templates select="* except (dbk:alt | dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']])" mode="#current"/>-->
              <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
            </table>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <table>
            <xsl:apply-templates select="@role | @css:*" mode="#current"/>
            <HTMLTABLE_TODO/>
            <xsl:apply-templates mode="#current"/>
          </table>
        </xsl:otherwise>
      </xsl:choose>
      <!--<xsl:for-each select="self::dbk:informaltable">
        <xsl:call-template name="css:other-atts"/>
        </xsl:for-each>-->
      <!-- extra content-type attribute at the contained table (also process css here, only id above?): -->
      <xsl:if test="dbk:textobject[not(every $elt in node() satisfies $elt/self::dbk:sidebar)]">
        <table-wrap-foot>
          <xsl:apply-templates select="dbk:textobject/dbk:para" mode="#current"/>
        </table-wrap-foot>
      </xsl:if>
    </table-wrap>
  </xsl:template>
  
  <xsl:template match="dbk:informaltable/dbk:alt | dbk:table/dbk:alt" mode="default">
    <alternatives>
      <xsl:for-each select="dbk:inlinemediaobject/dbk:imageobject/dbk:imagedata/@fileref">
        <graphic xlink:href="{.}"/>
      </xsl:for-each>
    </alternatives>
  </xsl:template>
  
  <xsl:template match="dbk:informaltable" mode="default_DISABLED">
    <array>
      <xsl:call-template name="css:content"/>
    </array>  
  </xsl:template>
  
  <xsl:template match="dbk:colspec | @colname | @nameend" mode="default"/>
  
  
  <!-- EPUB conditional content -->
  
  <xsl:template match="@condition" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>
  
  <!-- BIBLIOGRAPHY -->
  
  <xsl:template match="dbk:bibliography | dbk:bibliodiv" mode="default">
    <ref-list>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </ref-list>
  </xsl:template>

  <xsl:template match="dbk:biblioentry/@annotations" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>

  <xsl:template match="dbk:biblioentry" mode="default">
    <ref>
      <xsl:call-template name="css:content"/>
    </ref>
  </xsl:template>

  <xsl:template match="dbk:bibliomixed" mode="default">
    <ref>
      <mixed-citation>
        <xsl:call-template name="css:content"/>
      </mixed-citation>
    </ref>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomixed/@xreflabel" mode="default">
    <xsl:attribute name="id" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:info/dbk:bibliomisc" mode="default">
    <custom-meta>
      <meta-name><xsl:value-of select="@role"/></meta-name>
      <meta-value><xsl:call-template name="css:content"/></meta-value>
    </custom-meta>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomisc" mode="default">
    <mixed-citation>
      <xsl:if test="../@xml:id">
        <xsl:attribute name="id" select="../@xml:id"/>  
      </xsl:if>
      <xsl:call-template name="css:content"/>
    </mixed-citation>
  </xsl:template>
  
  <xsl:template match="dbk:biblioentry/@xml:id" mode="default"/>
  
  <xsl:template match="mixed-citation/@*[name() = ('css:margin-left', 'css:text-indent', 'content-type')]" mode="clean-up"/>
  
  <xsl:template match="sup/@xml:lang | sub/@xml:lang" mode="clean-up"/>
  
  <!-- equations -->
  
  <xsl:template match="dbk:equation" mode="default">
    <disp-formula>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </disp-formula>
  </xsl:template>
  
  <xsl:template match="dbk:inline-equation" mode="default">
    <inline-formula>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </inline-formula>
  </xsl:template>

  <xsl:function name="jats:is-page-anchor" as="xs:boolean">
    <xsl:param name="anchor" as="element(dbk:anchor)"/>
    <xsl:sequence select="exists($anchor/@xml:id[matches(., '^(cell)?page_[^_]')])"/>
  </xsl:function>
  

  <!-- not useful at this stadium. perhaps if the attribute usage is improved. Then it could become a styled-content element with style-type in a label -->
  <xsl:template match="@hub:numbering-inline-stylename" mode="clean-up"/>
  
</xsl:stylesheet>
