# Definitions
This folder keeps all Open API definitions. You will find most of the swagger documentation in these files. 
The declared shemas will be tested on each rswag requests. 

## Guidelines

**Do not use `example`**<br />
Use example generation from rswag. Do not document examples in definitions
``` 
# BAD
title: {type: :string, example: "Gello"}
```

```
# GOOD: 
run_example!(example_name: :ok)
```

**Use `title`**<br />
The `title` property will be used by the generator to generate function names and types name. 
Use it then to describe briefly the resource. 

```
# BAD: extended_data will be typed RelashionShipUserExtendedData
relashionship: {
  type: :object,
  properties: {
    user: {
      type: :object,
      properties: {
        extended_data: {type: :object}
      }
    }
  }
}
```

```
# GOOD: extended_data will be typed UserExtendedData
relashionship: {
  type: :object,
  properties: {
    user: {
      type: :object,
      properties: {
        extended_data: {type: :object, title: "User Extended Data"}
      }
    }
  }
}
```

**Use `required`**<br />
For `type: :object`, require the properties than are always presents. Typed languages like typescript will 
then resolve better the types, and your test coverages will be better. 

```
# BAD
hello: {
  type: :object,
  properties: {
    message: {type: :string}
  }
}
```

```
# GOOD
hello: {
  type: :object,
  properties: {
    message: {type: :string}
  },
  required: [:message]
}
```

**Use markdown and `<<~README`**<br />
For multi line description or more complete documentation, use Heredoc annotations to write your content. 
Use markdown:

```
# BAD
title: {type: :string, description: "my quiet long description\n, multilines."}
```

```
# GOOD
title: {
  type: :string, 
  description: <<~README
    my quiet long description
    , multilines.
  README
}
```
