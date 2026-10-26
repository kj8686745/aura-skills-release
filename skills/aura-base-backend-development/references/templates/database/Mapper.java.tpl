package {{PACKAGE}}.mapper;

import {{MAPPER_BASE_TYPE}};
import {{PACKAGE}}.entity.{{ENTITY_NAME}};
import org.apache.ibatis.annotations.Mapper;
{{MAPPER_IMPORTS}}

@Mapper
public interface {{ENTITY_NAME}}Mapper extends {{MAPPER_BASE_NAME}}<{{ENTITY_NAME}}> {
{{MAPPER_METHODS}}
}
