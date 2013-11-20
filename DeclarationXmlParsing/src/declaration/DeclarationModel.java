package declaration;

import javax.xml.namespace.QName;
import javax.xml.xquery.XQItemType;

public class DeclarationModel {

	private String type;
	private String questionId;
	private String xmlStore;
	private String language;
	private String filename;
	private String docId;
	
	public DeclarationModel(){}
	
	public DeclarationModel(String type, String questionId, String xmlStore,
			String language, String filename, String docId) {
		super();
		this.type = type;
		this.questionId = questionId;
		this.xmlStore = xmlStore;
		this.language = language;
		this.filename = filename;
		this.docId = docId;
	}
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	public String getQuestionId() {
		return questionId;
	}
	public void setQuestionId(String questionId) {
		this.questionId = questionId;
	}
	public String getXmlStore() {
		return xmlStore;
	}
	public void setXmlStore(String xmlStore) {
		this.xmlStore = xmlStore;
	}
	public String getLanguage() {
		return language;
	}
	public void setLanguage(String language) {
		this.language = language;
	}
	public String getFilename() {
		return filename;
	}
	public void setFilename(String filename) {
		this.filename = filename;
	}
	public String getDocId() {
		return docId;
	}
	public void setDocId(String docId) {
		this.docId = docId;
	}
	
	
}
