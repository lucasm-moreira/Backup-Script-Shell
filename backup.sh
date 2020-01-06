#!/bin/bash

#LIMPANDO ARQUIVO DE RELATORIO

> relatorio.txt

#VARIAVEIS

LISTA="lista_arquivos.txt"
DATA=$(date +%d-%m-%Y)
PACOTE="backup_$DATA.tar.gz"

#VARIAVEIS PARA BKP DO MYSQL

MY_BASE='***'
MY_USER='***'
MY_PASS='***'
MY_FILE='dump.sql'
SERVIDOR_REMOTO='***'

#VARIAVEIS PARA ENVIAR EMAIL

EMAIL_FROM='***'
EMAIL_TO='***'
EMAIL_USER_SMTP='***'
EMAIL_PASS_SMTP='***'
SERVIDOR_SMTP='outlook-com.olc.protection.outlook.com.'
ASSUNTO="RELATORIO_BACKUP $DATA"
MENSAGEM='SEGUE ANEXO RELATORIO DE BACKUP'
ANEXO=/root/files/relatorio.txt

#FUNCAO PARA COMPACTAR

fnCompactar(){
        tar -cvf $PACOTE -T $LISTA > /dev/null 2>&1

        if [ $? -ne 0 ]
        then
                fnErro "Problema ao compactar!"
        else
                fnSucesso "$PACOTE criado com sucesso!"
        fi
}

#FUNCAO PARA EXIBIR ERRO, CASO OCORRA

fnErro(){
        echo "[ERRO] - $1"
}

#FUNCAO PARA EXIBIR SUCESSO, SE O ARQUIVO FOR CRIADO CORRETAMENTE

fnSucesso(){
        echo "[OK] - $1"
}

#FUNCAO DE DUMP NO MYSQL

fnDump(){
        mysqldump -u $MY_USER -p$MY_PASS $MY_BASE > $MY_FILE 2>/dev/null

        if [ $? -eq 0 ]
        then
                fnSucesso "Dump da base $MY_BASE gerado com sucesso!"
        else
                fnErro "Problema ao realizar o Dump!"
        fi
}

#FUNCAO PARA ENVIAR BACKUP PARA O SERVIDOR REMOTO

fnEnvioRemoto(){
        scp $PACOTE $SERVIDOR_REMOTO:/root > /dev/null 2>&1

        if [ $? -eq 0 ]
        then
                fnSucesso "Pacote $PACOTE enviado para $SERVIDOR_REMOTO"
        else
                fnErro "Problema ao enviar backup para o servidor remoto"
        fi
}

#FUNCAO PARA CHECAR INTEGRIDADE

fnChecaIntegridade(){
        HASH_LOCAL=$(md5sum $PACOTE | awk '{print $1}')
        HASH_REMOTO=$(ssh $SERVIDOR_REMOTO md5sum $PACOTE | awk '{print $1}')

        if [ $HASH_LOCAL == $HASH_REMOTO ]
        then
                fnSucesso "Integridade checada - Arquivos iguais!"
        else
                fnErro "Arquivos nao integros!"
        fi
}

fnEnviaEmail(){
        sendEmail -f "$EMAIL_FROM" -t "$EMAIL_TO" -u "$ASSUNTO" -m "$MENSAGEM" -a $ANEXO -s "$SERVIDOR_SMTP" -xu "$EMAIL_USER_SMTP" -xp "$EMAIL_PASS_SMTP" -o tls=yes
}

fnDump >> relatorio.txt
fnCompactar >> relatorio.txt
fnEnvioRemoto >> relatorio.txt
fnChecaIntegridade >> relatorio.txt
fnEnviaEmail
