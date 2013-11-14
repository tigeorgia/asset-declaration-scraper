package declaration;

import java.util.HashMap;
import java.util.Map;

import javax.xml.namespace.QName;
import javax.xml.xpath.XPathVariableResolver;

public class DeclarationVariableResolver implements XPathVariableResolver {

	// local store of variable name -> variable value mappings
	Map<String, String> variableMappings = new HashMap<String, String>();

	// a way of setting new variable mappings 
	public void setVariable(String key, String value)  {
		variableMappings.put(key, value);
	}


	@Override
	public Object resolveVariable(QName variableName) {
		String key = variableName.getLocalPart();
		return variableMappings.get(key);
	}

}
