; author's 2013 note:
; This is a piece of assembly code from circa 1992-1993 and my first attempt at asm programming. A lot of comments here serve as a note-to-self on how specific operations work which was a brilliant idea
; considering that 20+ years have passed and I can still understand what I was thinking back then ;) Since the CPU architecture was slightly different back then, don't expect this thing to work flawlessly
; on a modern computer (not sure if a modern asm would even handle it without spitting out bugs or anything).
;

;
; Pobranie daty za pomoca funkcji 2ah:
; cx - rok
; dh - miesiac
; dl - dzien
;
; --- Tu podaj numerycznie date, od ktorej chcesz odliczac dni ---

_DZIEN_=27
_MIESIAC_=01
_ROK_=1992

; ---------------------------POCZATEK-KODU-PROGRAMU-----------------------------


TITLE czas.asm
SUBTTL wersja 1.2
Program SEGMENT
RADIX 10                            ; Przyjecie systemu dziesietnego jako domyslny.
ASSUME CS:Program, DS:Data
ASSUME SS:Stos_Programu

%OUT Assemblacja segmentu Stosu...
    Stos_Programu SEGMENT STACK         ; Dla spokoju - rezerwujemy 100 "nieokreslonych"
    db 100 DUP(?)                       ; bajtow, ktore beda pelnic funkcje stosu. 
Stos_Programu ENDS
 
%OUT Assemblacja segmentu Danych...
Data SEGMENT
    Napis1 db 'Minelo juz ','$'         ; <--- Tu wstaw swoj komunikat.
    Napis2 db ' dzien ','$'
    Napis3 db ' dni','$'
    Napis4 db ' rok ','$'
    Napis5 db ' lat ','$'
    Napis6 db ' lata ','$'
    Napis7 db '(366 dzien roku przestepnego)','$'
    Linia db ' ',13,10,'$'
    Blad1 db 'Blad: Zadana data jeszcze nie nastapila',13,10,'$'
    Blad2 db 'Dziwne... wydaje mi sie, ze to wlasnie dzis ;)',13,10,'$'
    rok dw ?                            ; Gdy zmieniam z dw na db, przy dh>0 mam o jeden 
    mie db ?                            ; dzien za duzo... ale to i tak kwestia 1 bajta.
    dzi db ?
    iloraz db ?
    reszta2 db ?                        ; Dziwne... najpierw MUSI byc reszta2, potem 
    reszta1 db ?                        ; reszta1... inaczej nie dziala...
    iloraz2 db ?
    reszta3 db ?
    dziesiec db 10
    cztery db 4
    przestepny db ?
Data ENDS

%OUT Assemblacja Makra...
KomunikatBledu MACRO numer          ; Makro wywolujace komunikaty bledu.
    Local ZlaData, ToDzisiaj
    Local Przerwanie
    mov bx,numer
    mov ah,09h
    cmp bx,1                        ; W zaleznosci od parametru (numer) komunikatu
    je ZlaData                      ; makro bedzie wypisywalo na ekranie odpowiedni 
    cmp bx,2                        ; komunikat bledu.
    je ToDzisiaj
ZlaData:
    mov dx,offset Blad1
    jmp Przerwanie
ToDzisiaj:
    mov dx,offset Blad2
    jmp Przerwanie
Przerwanie:
    int 21h
ENDM

org 100h
%OUT Assemblacja wstepnej czesci programu...
Start:
    mov ax,Data
    mov ds,ax
    mov ah,2ah                      ; Funkcja 2ah - pobranie daty z zegara systemowego.
    int 21h
    mov word ptr[rok],cx            ; Skopiowanie pobranej wartosci roku do [rok].
    mov byte ptr[mie],dh            ; Skopiowanie miesiaca.
    mov byte ptr[dzi],dl            ; Skopiowanie dnia.
    xor si,si                       ; Zerowanie rej. SI (bedzie potrzebny pozniej).
    sub cx,_ROK_                    ; Odjecie od obecnego roku, daty, od ktorej liczymy.
    cmp cx,0d                       ; Jesli wartosc roku jest ujemna...
    jnl SprawdzPrzestepnosc
    KomunikatBledu 1                ; ...to wyswietl komunikat i zakoncz program (data
    jmp Koniec                      ; jeszcze nie nastapila). 

%OUT Assemblacja sekcji SprawdzPrzestepnosc...
SprawdzPrzestepnosc:                ; Sprawdzenie przestepnosci roku i dnia.
    cmp dl,29                       ; Jedna mozliwosc, to gdy biezacym dniem jest 29
    jne Przypadek2                  ; lutego, a odliczamy od dnia innego niz 29.02. 
    cmp dh,2                        ; Wtedy dla poprawnosci wyniku trzeba zaznaczyc, ze
    jne Przypadek2                  ; kazdy 29.02 jest dodatkowym dniem przestepnym
    mov byte ptr[przestepny],1      ; (366 dzien roku).

Przypadek2:                         ; Przypadek2 zachodzi, gdy odliczamy od 29 lutego.
    mov ax,_DZIEN_                  ; Wtedy w kazdym roku przestepnym 366 dniem roku
    cmp ax,29                       ; staje sie 01.03 i trzeba ten fakt zaznaczyc.
    jne ObliczRoznice               ; byte ptr[przestepny] to "wskaznik przestepnosci",
    mov ax,_MIESIAC_                ; jesli jest ustawiony na 1, to znaczy, ze obecny
    cmp ax,02                       ; dzien jest dodatkowym dniem przestepnym (366 dniem
    jne ObliczRoznice               ; roku)
    cmp dl,01
    jne ObliczRoznice
    cmp dh,03
    jne ObliczRoznice

CzyRokPrzestepny:                   ; Jesli odliczamy od 29.02 i mamy obecnie 01.03, to
    mov ax,word ptr[rok]            ; sprawdz, czy mamy teraz rok przestepny.
    sub ax,1000                
    div cztery                      ; Rok przestepny podzielony przez 4 nie daje reszty,
    cmp ah,0                        ; wiec jesli reszta w rej. AH jest rowna 0 - mamy 
    jne ObliczRoznice               ; rok przestepny i trzeba dodac jeden dzien do
    mov byte ptr[przestepny],1      ; ogolnego wyniku i ustawic wskaznik przestepnosci.
    add si,1                        ; W rejestrze SI zostaje umieszczony dodatkowy dzien.

ObliczRoznice:
    mov word ptr[rok],cx            ; Przenies roznice lat do [rok]. 
    sub dh,_MIESIAC_                ; Oblicz roznice miesiecy od zadanej daty.
    mov cx,word ptr[dzi]            ; Przenies wartosc dzisiejszego dnia do rej. CX...
    sub cx,_DZIEN_                  ; ...i oblicz roznice dni od zadanej daty.

%OUT Assemblacja sekcji SprawdzPoprawnoscDaty...
SprawdzPoprawnoscDaty:
    cmp dh,0d                       ; Jesli roznica miesiecy jest mniejsza rowna 
    jle SprawdzMiesiac              ; zero, skocz do SprawdzMiesiac, jesli zas 
    mov bl,15d                      ; wynik jest wiekszy od zera, to ustaw wartosc 

SprawdzMiesiac:                     ; rejestru BL na 15, ktory robi tu za znacznik.
    cmp bl,15d                      ; Sprawdz, czy roznica miesiecy jest wieksza 
    jne SprawdzDzien                ; od zera, jesli nie, to sprawdz dni.
    jmp UstalWariant     

SprawdzDzien:
    cmp cx,0d                         ; Jesli roznica dni jest nie wieksza od zera... 
    jng SprawdzRok                    ; ...to sprawdzaj dalej (tym razem rok)...
    cmp dh,0d
    jl SprawdzRok
    jmp UstalWariant

SprawdzRok:
    cmp word ptr[rok],0               ; ...i jesli roznica lat jest nie wieksza od 
    jg UstalWariant                   ; zera, to skoncz program. 
    cmp dh,0                          ; Sprawdzanie "warunkow bledu" (jesli jest to 
    jne DataNieNastapila              ; tzw. blad dnia dzisiejszego, czyli jesli 
    cmp cx,0                          ; chce ktos odliczac od obecnego dnia, to 
    jne DataNieNastapila              ; wywolaj makro KomunikatBledu z komunikatem 
    cmp word ptr[rok],0               ; numer 2. W przeciwnym razie wywolaj to makro 
    jne DataNieNastapila              ; z komunikatem numer 1 (data jeszcze nie 
    KomunikatBledu 2                  ; nastapila).
    jmp Koniec

DataNieNastapila:
    KomunikatBledu 1
    jmp Koniec

%OUT Assemblacja sekcji UstalWariant...
UstalWariant:
    cmp cx,0d                         ; Sprawdzanie znaku roznicy dni. Jesli roznica
    jl RoznicaDniUjemna               ; dni jest mniejsza od zera, to skocz do
    cmp bl,15d                        ; RoznicaDniUjemna, w przeciwnym razie sprawdz
    jne RoznicaMiesiecyMniejszaOdZera ; jaki jest znak roznicy miesiecy (czyli czy 
    jmp ProgramGlowny                 ; rejestr BH jest ustawiony na 15).  

RoznicaDniUjemna:    
    cmp bl,15d                        ; Sprawdz czy roznica miesiecy jest wieksza od 
    je RoznicaMiesiecyWiekszaOdZera   ; zera i zaleznie od wyniku postepuj zgodnie z 
    cmp word ptr[rok],0               ; procedurami.
    jg RoznicaLatWiekszaOdZera
    jmp Wariant2
    
RoznicaLatWiekszaOdZera:
    cmp cx,0d                         ; Jeszcze raz sprawdz znak roznicy dni.
    jl Wariant4                  
    jmp Koniec
    
RoznicaMiesiecyWiekszaOdZera:
    cmp word ptr[rok],0               ; Sprawdz, czy roznica lat jest rowna zero.
    jng ProgramGlowny             
    jmp Wariant2               
    
RoznicaMiesiecyMniejszaOdZera:
    cmp word ptr[rok],0
    jg Wariant3                      
    cmp cx,0d
    jg ProgramGlowny                    
    jmp Koniec
    
Wariant1:
    dec byte ptr[rok]
    
Wariant2:
    mov bh,10d                        ; Kolejny znacznik: jesli program tutaj trafil 
    jmp ProgramGlowny                 ; to znaczy, ze bedzie trzeba dodac do liczby 
    
Wariant3:                             ; dni w CX jeszcze 365.
    cmp dh,0d                         ; I znowu sprawdzanie miesiecy.
    je ProgramGlowny
    dec byte ptr[rok]        
    jmp ProgramGlowny
    
Wariant4:
    dec byte ptr[rok] 
    mov bh,10d                        ; Jeszcze raz znacznik, ktory wskaze, ze 
    cmp dh,0d                         ; nalezy dodac 365 dni do CX. 
    jl UstawDI
    jnl ProgramGlowny
    
UstawDI:
    cmp word ptr[rok],0d
    jg ProgramGlowny
    mov di,1d                         ; Znacznik -- jesli roznica lat jest wieksza 
                                      ; od zera, to trzeba bedzie to zaznaczyc przy
                                      ; wyswietleniu wyniku.  
ProgramGlowny:                        ; Jesli w DH nie bedzie zera, to musimy te 
    cmp dh,0d                         ; niezerowe liczby odpowiednio zamienic na 
    jnz RoznicaMiesiecyRoznaOdZera    ; dni w sekcji RoznicaMiesiecyRoznaOdZera, a 
    jmp Kontynuacja                   ; gdy w DH bedzie 0, kontynuuj program.

%OUT Assemblacja sekcji RoznicaMiesiecyRoznaOdZera...                                  
RoznicaMiesiecyRoznaOdZera:           ; Ta sekcja zamieni wszystkie miesiace w DH na 
    cmp dh,0d                         ; dni i bedzie je dodawac do CX - tak dlugo, 
    jge WiekszeRowneZero              ; az w DH osiagniemy 0.
    
Dodaj12Miesiecy:                      ; Jesli roznica miesiecy jest ujemna, to 
    add dh,12d                        ; znaczy, ze trzeba bedzie dodac 12 miesiecy
    
WiekszeRowneZero:                     ; dla zachowania poprawnosci wyswietlanego
    dec byte ptr[mie]                 ; wyniku.
    cmp byte ptr[mie],0
    jg UstalMiesiac
    
DodajMiesiace:
    mov bl,12d
    add bl,byte ptr[mie]
    mov byte ptr[mie],bl
    
UstalMiesiac:                         ; Ustalenie, jaki miesiac jest obecnie w
    cmp byte ptr[mie],2               ; "obiegu" petli.
    je Luty
    cmp byte ptr[mie],4
    je KCWL                           ; Kwiecien Czerwiec Wrzesien Listopad - 30 dni.
    cmp byte ptr[mie],6
    je KCWL                           
    cmp byte ptr[mie],9
    je KCWL
    cmp byte ptr[mie],11
    je KCWL
    jne SMMLSPG                       ; Pozostale miesiace - 31 dni.
    
Luty:                                 ; Luty - przyjeta stala wartosc - 28 dni.
    rept 28
    inc cx                            ; 28 razy zwieksz liczbe dni w CX.
    endm
    jmp Sprawdzenie
    
KCWL:
    rept 30                           ; 30 razy zwieksz liczbe dni w CX.
    inc cx
    endm
    jmp Sprawdzenie
    
SMMLSPG:
    rept 31                           ; 31 razy zwieksz liczbe dni w CX.
    inc cx
    endm
    jmp Sprawdzenie
    
Sprawdzenie:
    cmp dh,0                          ; Zaleznie od znaku roznicy miesiecy w DH, 
    jge Dodatni                       ; nalezy albo zwiekszyc jego wartosc o 1, albo 
    jl Ujemny                         ; zmniejszyc. Wszystko to dlatego, ze musimy 
    
Dodatni:                              ; osiagnac w DH 0.
    dec dh
    jmp ProgramGlowny
    
Ujemny:
    inc dh
    jmp ProgramGlowny 

%OUT Assemblacja sekcji Kontynuacja...
Kontynuacja:
    add cx,si                  ; Tu dodajemy wszystkie dodatkowe dni zebrane w SI.
    cmp bh,10d                 ; Sprawdz czy jest ustawiony znacznik sygnalizujacy, 
    jne UstalCzyRok            ; ze trzeba dodac 365 dni do CX...

DodajRok:                      ; ...i jesli jest ustawiony, to zrob to.
    mov ax,cx
    mov cx,365d
    add cx,ax

UstalCzyRok:                   ; Sprawdzamy, czy trzeba bedzie zasygnalizowac przy 
    cmp cx,365d                ; wyswietleniu wyniku, ze minal juz pelny rok (czyli, 
    jng MniejNiz365Dni         ; ze minelo juz przynajmniej raz 365 dni), a jesli
                               ; ilosc dni w CX jest mniejsza niz 365 dni, skocz do 
                               ; odpowiedniej etykiety.
Ponad365Dni:             
    cmp word ptr[rok],0        ; Sprawdz jeszcze, czy roznica lat jest wieksza od
    jng MniejNiz365Dni         ; zera...

WiekszyOdZera:                 ; ...i jesli ten warunek rowniez bedzie spelniony, 
    sub cx,365d                ; odejmij od CX 365 dni. 

MniejNiz365Dni:
    cmp di,1d                  ; Jesli roznica lat jest wieksza od zera....
    jne ZacznijDzielenie

OdejmijRok:
    sub cx,365d                ; ...odejmij 365 dni.

%OUT Assemblacja sekcji ZacznijDzielenie...
ZacznijDzielenie:              ; W tej sekcji program konwertuje kody ASCII wynikow, 
    mov ax,cx                  ; aby moc je pozniej wyswietlic poprawnie na ekranie.
    div dziesiec               ; Podziel liczbe w AX (czyli ta z CX) przez 10.
    cmp al,0                   ; Jesli otrzymamy ulamek dziesietny mniejszy od 1, to 
    jz Jednocyfrowa            ; znaczy ze wyswietlimy wynik jednocyfrowy i dalszy 
                               ; podzial jest niepotrzebny (skok do Jednocyfrowa).
    add ah,48d                 ; Dodaj do kodu ASCII reszty liczbe 48 (kod ASCII 
    mov bh,ah                  ; zera) i przenies ta reszte na chwile do BH...
    mov dh,al                  ; ...a potem przenies glowny wynik dzielenia do DH...
    mov byte ptr[reszta2],dh   ; ...i umiesc go w [reszta2], zeby... 
    mov ax,word ptr[reszta2]   ; jako slowo wrocil do AX, aby dzielic go dalej.
    mov byte ptr[reszta2],bh   ; Teraz umiesc reszte z pierwszego dzielenia w
                               ; [reszta2] i daj jej juz spokoj.
DzielDalej:                    ; Dzielimy liczbe w AX jeszcze raz i jesli tym
    div dziesiec               ; razem glowny wynik dzielenia jest ulamkiem 
    cmp al,0                   ; dziesietnym mniejszym od 1...
    jz Dwucyfrowa              ; ...to znaczy, ze liczba jest dwucyfrowa (skok).
    mov bl,1                   ; Wykorzystujemy rejestr BL jako znacznik, ze 
                               ; wyswietlana liczba bedzie trzycyfrowa.
    add ah,48d                 ; Dodawanie liczby 48 do kodu ASCII wyniku (AL) i
    add al,48d                 ; reszty (AH) z dzielenia i...
    mov byte ptr[reszta1],ah   ; ...przenoszenie ich do odpowiednich komorek.
    mov byte ptr[iloraz],al
    jmp DzieliWyswietlLata     ; Koniec dzielenia, skaczemy dalej.
    
Dwucyfrowa:                    ; Tu przeskakujemy, gdy wartosc AL z drugiego  
    add ah,48d                 ; dzielenia wynosi 0.
    mov byte ptr[reszta1],ah
    mov byte ptr[iloraz],20h   ; Aby wyeliminowac dodatkowa spacje, w komorce 
    jmp DzieliWyswietlLata     ; [iloraz] umieszczamy kod znaku Backspace.
    
Jednocyfrowa:                  ; A tu pojawiamy sie, gdy juz po pierwszym dzieleniu 
    add ah,48d                 ; wynik w AL jest rowny 0.
    mov byte ptr[reszta1],ah
    mov byte ptr[iloraz],20h
    mov bh,2                   ; Rejestr BH z wartoscia 2 - znacznik, ze wynik jest 
                               ; jednocyfrowy.

%OUT Assemblacja sekcji DzieliWyswietlLata...
DzieliWyswietlLata:
    mov ah,09h                 ; Drukujemy na ekranie pierwszy napis.
    mov dx,offset Napis1
    int 21h
    cmp cx,365d
    jnge NieDwaLata
    sub cx,365d
    
NieDwaLata:
    cmp byte ptr[rok],0d       ; Sprawdzamy, czy roznica lat jest wieksza od zera -
    jz MniejNizRok             ; jesli tak, sekcja PonadRok wydrukuje stosowny 
    
PonadRok:                      ; komunikat uwzgledniajacy ten fakt. 
    mov ax,word ptr[rok]       ; Przenosimy roznice lat do AX...
    div dziesiec               ; ...aby podzielic ja przez 10...
    cmp al,0                   ; ...i sprawdzic, czy jest to wartosc dwucyfrowa.
    jz Niedwucyfrowa
    add al,48d                 ; Jesli jest, to postepujemy podobnie jak w przypadku
    add ah,48d                 ; dni.
    mov byte ptr[iloraz2],al   ; Przenies iloraz do [iloraz2]...
    mov byte ptr[reszta3],ah   ; ...oraz reszte do [reszta3]...
    mov ah,02h
    mov dl,byte ptr[iloraz2]   ; ...a nastepnie wyswietl obie wartosci.
    int 21h
    mov dl,byte ptr[reszta3]
    int 21h
    jmp ZacznijWyswietlac
    
Niedwucyfrowa:
    mov ah,02h
    mov dl,byte ptr[rok]
    add dl,48d
    int 21h

%OUT Assemblacja sekcji ZacznijWyswietlac...
ZacznijWyswietlac:                
    mov ah,09h
    cmp byte ptr[rok],1        ; Dla zachowania poprawnosci gramatycznej trzeba 
    jne ZobaczCzyWiecejNiz5    ; sprawdzic wartosc roznicy lat. Jesli jest to 1, 
    mov dx,offset Napis4       ; musi zostac wyswietlony napis 'rok', jesli wartosc,
    int 21h                    ; ktora jest mniejsza od 5 - napis 'lata', zas w 
    jmp SprawdzCzyPelnyRok     ; pozostalych przypadkach napis 'lat'.
    
ZobaczCzyWiecejNiz5:
    cmp word ptr[rok],5
    jl MniejNiz5
    mov ah,09h
    mov dx,offset Napis5
    int 21h
    jmp SprawdzCzyPelnyRok
    
MniejNiz5:                     ; tu skaczemy, gdy minelo mniej niz 5 lat.
    mov ah,09h
    mov dx,offset Napis6
    int 21h
    
SprawdzCzyPelnyRok:
    cmp cx,0                   ; Przy pelnym roku nie wypisuj, ze minelo 0 dni.
    je RysujLinie
    cmp byte ptr[przestepny],1 ; Czy mamy 366 dzien roku przestepnego? Jesli tak,
    jne MniejNizRok            ; wydrukuj stosowny do tego komunikat (Napis7)
    mov dx,offset Napis7
    int 21h
    jmp RysujLinie
    
MniejNizRok:
    cmp bl,1                   ; Sprawdzamy, czy wynik jest trzycyfrowy.
    je WyswietlWynik
    
CofnijZnak:                    ; Jesli wynik jest dwu, badz jednocyfrowy, drukujemy 
    mov ah,02h                 ; znak Backspace by pozbyc sie dodatkowej spacji,
    mov dl,08h                 ; (gdzie normalnie powinna byc trzecia cyfra wyniku).
    int 21h
    
WyswietlWynik:
    mov ah,02h
    mov dl,[iloraz]
    int 21h
    mov dl,[reszta1]
    int 21h
    mov dl,[reszta2]
    int 21h
    cmp bh,2                   ; A tu sprawdzamy, czy wynik jest jednocyfrowy...                
    jne Napisy
    
DlaJednocyfrowej:
    mov dl,08h                 ; ...i w razie zgodnosci drukujemy jeszcze jeden 
    int 21h                    ; znak Backspace aby pozbyc sie jeszcze jednej spacji 
    
Napisy:                        ; (zbednej w przypadku wyniku jednocyfrowego).
    mov ah,09h
    cmp cx,1d                  ; Zapewnienie poprawnosci gramatycznej w przypadku 
    jne WiecejNizJeden         ; wyswietlania liczby dni - napis 'dzien', jesli 
    mov dx,offset Napis2       ; w CX znajduje sie dokladnie 1 dzien, lub napis 
    int 21h                    ; 'dni' w pozostalych przypadkach.
    jmp Koniec
    
WiecejNizJeden:
    lea dx,Napis3              ; Rownowazne zapisowi mov dx,offset Napis3.
    int 21h
    
RysujLinie:
    lea dx,Linia               ; Rownowazne zapisowi mov dx,offset Linia.
    int 21h
    
Koniec:
    mov ah,4ch
    int 21h
    
%OUT Assemblacja zakonczona pomyslnie!
Program ENDS
END Start

; ------------------------------------------------------------------------------
;
; KOMENTARZE:
; Ta wersja programu jest podatna na bledy przy wpisywaniu daty, od ktorej ma
; nastepowac odliczanie. Mozna w ten sposob np. odmierzac czas od 32 stycznia
; albo 30 lutego. Niewygodny jest tez sposob wprowadzania daty -- trzeba to 
; zrobic w kodzie zrodlowym, przez co pozniejsza zmiana jest niemozliwa. Dobrym
; rozwiazaniem byloby przystosowanie kodu do odczytania daty odliczania z zewne-
; trznego pliku.
