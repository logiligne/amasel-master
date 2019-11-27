define 'cfg/default_print_template', [], ()->
	pre : '''
<!doctype html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<title>Labels to print</title>
		<style>
			@page { 
					size: 210mm 270mm;	 /* auto is the initial value */ 
					/* this affects the margin in the printer settings */ 
					/* margin: 0mm 0mm 0mm 0mm;	 */
					margin-top: {{ pageMarginTop }};
					margin-bottom: {{ pageMarginBottom }};
					margin-left: {{ pageMarginLeft }};
					margin-right: {{ pageMarginRight }};
			}
			body {
					width: {{ pageWidthWithoutMargins }};
					outline: 1px solid;
			}
			.label{
					width: {{ labelWidth }}; /* Maybe this should be + padding */
					height: {{ labelHeight }}; /* Maybe this should be + padding */
					padding-top: {{ labelPaddingTop }};
					padding-bottom: {{ labelPaddingBottom }};
					padding-right: {{ labelPaddginRight }};
					padding-left: {{ labelPaddingLeft }};
					margin-right: {{ labelHorizontalSpacing }}; 
					margin-bottom: {{ labelVerticalSpacing }}; 
					text-align: {{ labelTextAlign }};
					float: left;
					overflow: hidden;
					outline: 1px solid;
					font-family: Arial, Helvetica, sans-serif;
			}
			@media print {
				body{
					overflow: hidden;
					outline: none;
				}
				.label{
					outline: none;
				}
			}
			.page-break	 {
					clear: left;
					display:block;
					page-break-after:always;
			}
		</style>
	</head>
	<body onload="setTimeout(function(){window.print();},0);">
'''
	label : '''
{{ShippingAddress.Name}}
{{ShippingAddress.AddressLines}}
{{ShippingAddress.PostalCode}} {{ShippingAddress.City}}
{{ShippingAddress.Country}}
'''
	order : '''
Bestellnummer: {{ AmazonOrderId }}<br />
Vielen Dank f&uuml;r Ihren Einkauf bei RoxxTox auf {{ SalesChannel }} Marketplace.
<table border="1" bordercolor="#ccc" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">
	<thead>
	</thead>
	<tbody>
		<tr>
			<td><strong>Lieferanschrift:</strong><br />
			{{ShippingAddress.Name}}<br />
			{{ShippingAddress.AddressLines}}<br />
			{{ShippingAddress.PostalCode}} {{ShippingAddress.City}}<br />
			{{ShippingAddress.Country}}</td>
			<td>Bestellt am: {{ PurchaseDate }}<br />
			Versandart:<br />
			Name des K&auml;ufers:<br />
			Name des Verk&auml;ufers:&nbsp; roxxtox.com</td>
		</tr>
	</tbody>
</table>
&nbsp;

<table border="1" cellpadding="0" cellspacing="0" class="item-list" style="border-collapse: collapse; width: 100%;" width="100%">
	<tbody>
		<tr>
			<th width="10%">Menge</th>
			<th width="65%">Produktdetails</th>
			<th width="25%">Gesamt</th>
		</tr>
		<tr>
			<td align="center" width="10%">{{item.QuantityShipped}}</td>
			<td width="65%">{{item.Title}}<br />
			<strong>H&auml;ndler-SKU:</strong> {{ item.SellerSKU}}<br />
			<strong>ASIN:</strong> {{ item.ASIN }}</td>
			<td align="center" width="25%">
			<table border="0" cellpadding="1" cellspacing="0" width="100%">
				<tbody>
					<tr>
						<td align="right" width="60%">Zwischensumme:</td>
						<td align="right" nowrap="nowrap">{{ item.ItemPrice.CurrencyCode }} {{ item.ItemPrice.Amount }}</td>
					</tr>
					<tr>
						<td align="right" width="60%">Versand:</td>
						<td align="right" nowrap="nowrap" width="40%">{{ item.ShippingPrice.CurrencyCode }} {{ item.ShippingPrice.Amount }}</td>
					</tr>
					<tr>
						<td colspan="2">
						<hr color="#cccccc" noshade="noshade" size="1" /></td>
					</tr>
					<tr>
						<td align="right">Summe:</td>
						<td align="right" nowrap="nowrap">{{ item.ItemPrice.CurrencyCode }} {{ 1*item.ShippingPrice.Amount + 1*item.ItemPrice.Amount }}</td>
					</tr>
				</tbody>
			</table>
			</td>
		</tr>
		<tr>
			<td align="right" colspan="3"><strong>SUMME DER BESTELLUNG: </strong>{{OrderTotal.CurrencyCode}} {{OrderTotal.Amount }}</td>
		</tr>
	</tbody>
</table>
'''
	post : '''

	</body>
</html>
'''