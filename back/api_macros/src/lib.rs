use proc_macro::TokenStream;
use quote::quote;
use syn::{ItemStruct, parse_macro_input, parse_quote, Type};

fn optional(ty: &Type) -> bool {
    matches!(ty, Type::Path(p) if p.path.segments.last().map_or(false, |s| s.ident == "Option")) 
}

fn prepare(input: &mut ItemStruct, omit_none: bool) {
    input.vis = parse_quote!(pub);
    for field in input.fields.iter_mut() {
        field.vis = parse_quote!(pub);
        if omit_none && optional(&field.ty) {
            field.attrs.push(parse_quote!(#[serde(skip_serializing_if = "Option::is_none")]));
        }
    }
}

#[proc_macro_attribute]
pub fn data(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let mut input = parse_macro_input!(item as ItemStruct);
    prepare(&mut input, false);
    quote! {
        #[derive(Debug, serde::Deserialize, serde::Serialize)]
        #[serde(rename_all = "camelCase")]
        #input
    }.into()
}

#[proc_macro_attribute]
pub fn dto(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let mut input = parse_macro_input!(item as ItemStruct);
    prepare(&mut input, true);
    quote! {
        #[derive(Debug, serde::Serialize)]
        #[serde(rename_all = "camelCase")]
        #input
    }.into()
}
