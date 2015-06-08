class xmlfile {
	__New(name, path := ""){
		file := path ? path : A_WorkingDir "\" name ".xml"
		temp:=ComObjCreate("MSXML2.DOMDocument")
		temp.setProperty("SelectionLanguage","XPath")
		this.xml:=temp
		ifexist %file%
			temp.load(file),this.xml:=temp
		else
			this.xml:=this.CreateElement(temp,name)
		this.file:=file
	}
	
	__Get(){
		this.transform()
		return this.xml.xml
	}
	
	move(newnode, node) {
		node.ParentNode.InsertBefore(newnode, node)
	}
	
	; add a new node, with attributes and text. dup if you wanna make a duplicate.
	add(path,att:="",text:="",dup:=0){
		p:="/",dup1:=this.ssn("//" path)?1:0,next:=this.ssn("//" path),last:=SubStr(path,InStr(path,"/",0,0)+1)
		if !next.xml{
			next:=this.ssn("//*")
			Loop,Parse,path,/
				last:=A_LoopField,p.="/" last,next:=this.ssn(p)?this.ssn(p):next.appendchild(this.xml.CreateElement(last))
		}
		if(dup&&dup1)
			next:=next.parentnode.appendchild(this.xml.CreateElement(last))
		for a,b in att
			next.SetAttribute(a,b)
		if(text!="")
			next.text:=text
		return next
	}
	
	; search for nodes 
	search(node,find,return=""){
		found:=this.xml.SelectNodes(node "[contains(.,'" RegExReplace(find,"&","')][contains(.,'") "')]")
		while,ff:=found.item(a_index-1)
			if (ff.text=find){
				if return
					return ff.SelectSingleNode("../" return)
				return ff.SelectSingleNode("..")
			}
	}
	
	; return a node and an array containing it's attributes
	get(path) {
		list := []
		while aa:=(t?t:t:=this.sn(path)).item[A_Index-1], ea:=xmlfile.ea(aa)
			list[aa]:=ea
		return list
	}
	
	find(info*){
		doc:=info.1.NodeName?info.1:this.xml
		if(info.1.NodeName)
			node:=info.2,find:=info.3
		else
			node:=info.1,find:=info.2
		if InStr(find,"'")
			return doc.SelectSingleNode(node "[.=concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "')]/..")
		else
			return doc.SelectSingleNode(node "[.='" find "']/..")
	}
	
	ssn(path){
		return this.xml.SelectSingleNode(path)
	}
	
	sn(path){
		return this.xml.SelectNodes(path)
	}
	
	; transform xml to readable format
	transform(x:=1){
		static
		if !IsObject(xsl){
			xsl:=ComObjCreate("MSXML2.DOMDocument")
			style=
			(
			<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
			<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
			<xsl:template match="@*|node()">
			<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
			<xsl:for-each select="@*">
			<xsl:text></xsl:text>
			</xsl:for-each>
			</xsl:copy>
			</xsl:template>
			</xsl:stylesheet>
			)
			xsl.loadXML(style),style:=null
		} loop % x
			this.xml.transformNodeToObject(xsl,this.xml)
	}
	
	; save to file
	save(transform := true){
		if transform
			this.Transform()
		file:=fileopen(this.file,3,"UTF-8"),file.seek(0),file.write(this[]),file.length(file.position)
	}
	
	; EasyAttribute - easy way to get attributes™
	ea(path){
		list:=[]
		nodes:=path.nodename?path.SelectNodes("@*"):path.text?this.sn("//*[text()='" path.text "']/@*"):!IsObject(path)?this.sn(path "/@*"):""
		while,n:=nodes.item(A_Index-1)
			list[n.nodename]:=n.text
		return list
	}
	
	delete(node){
		node.ParentNode.RemoveChild(node)
	}
	
	CreateElement(doc,root){
		return doc.AppendChild(this.xml.CreateElement(root)).parentnode
	}
}

sn(node,path){
	return node.selectnodes(path)
}

ssn(node,path){
	return node.selectsinglenode(path)
}