# Ícone Android do IFPR

A marca exibida nas telas é desenhada por `lib/presentation/widgets/ifpr_mark.dart`: um círculo vermelho e nove blocos verdes em uma grade de três colunas e quatro linhas. Não havia uma imagem de logo para simplesmente copiar. O launcher Android usava os PNGs padrão do Flutter.

## O que foi necessário

1. Reproduzir a grade, o espaçamento e os cantos arredondados da marca em `android/app/src/main/res/drawable/ic_launcher_foreground.xml`. O gerador lê o verde `#32A041` e o vermelho `#C8191E` diretamente de `lib/app/theme/app_colors.dart`.
2. Substituir os cinco arquivos `mipmap-*/ic_launcher.png` pelas versões da marca com fundo branco: 48, 72, 96, 144 e 192 pixels, respectivamente para mdpi, hdpi, xhdpi, xxhdpi e xxxhdpi. Esses arquivos atendem aos Androids anteriores à API 26.
3. Adicionar `mipmap-anydpi-v26/ic_launcher.xml`, que combina a marca vetorial com um fundo branco. O Android 8 ou superior aplica o formato escolhido pelo launcher, como círculo ou quadrado arredondado. A marca fica centralizada com margem para evitar cortes.
4. Adicionar `mipmap-anydpi-v33/ic_launcher.xml`, com a camada `monochrome`. No Android 13 ou superior, launchers compatíveis podem aplicar as cores do tema quando o usuário ativa ícones temáticos; no modo normal, permanecem as cores institucionais.

O manifesto já continha `android:icon="@mipmap/ic_launcher"`; foi mantido. É essa referência que faz o Android escolher automaticamente a variante adequada. Alterar apenas o widget Flutter não altera o ícone do aplicativo instalado.

Os recursos seguem a [documentação oficial de ícones adaptativos do Android](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

## Como regenerar

Os ícones já estão versionados: compilar o aplicativo não exige Python nem uma dependência Flutter adicional. Para recriar os PNGs e o vetor após mudar as cores ou a geometria:

```bash
python3 -m venv /tmp/piramidgame-icons
/tmp/piramidgame-icons/bin/pip install Pillow
/tmp/piramidgame-icons/bin/python scripts/gerar_icones_android.py
```

A geometria é reproduzida pelo script; se o desenho de `IfprMark` mudar, ajuste também a grade e as medidas no gerador.

Compile e instale uma nova versão para conferir o ícone na lista de aplicativos:

```bash
flutter build apk --debug
flutter install --debug
```

Hot reload não atualiza recursos nativos. Se o launcher mantiver o ícone anterior em cache, reinicie-o após instalar a nova versão.
