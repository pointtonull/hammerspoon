FasdUAS 1.101.10   ��   ��    k             l    & ����  O     &  	  k    % 
 
     r        6       4  �� 
�� 
prcs  m    ����   =  	     1   
 ��
�� 
pisf  m    ��
�� boovtrue  o      ���� 0 frontprocess frontProcess      r        n        1    ��
�� 
idux  o    ���� 0 frontprocess frontProcess  o      ���� 0 	activepid 	activePID      r        n        1    ��
�� 
bnid  o    ���� 0 frontprocess frontProcess  o      ���� 0 bundleid bundleID    ��   r     % ! " ! n     # # $ # 1   ! #��
�� 
pnam $ o     !���� 0 frontprocess frontProcess " o      ���� 0 
activename 
activeName��   	 m      % %�                                                                                  sevs  alis    \  Macintosh HD               �!��BD ����System Events.app                                              �����!��        ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    M a c i n t o s h   H D  -System/Library/CoreServices/System Events.app   / ��  ��  ��     & ' & l  ' � (���� ( O   ' � ) * ) Q   / � + , - + k   2 M . .  / 0 / r   2 7 1 2 1 1   2 5��
�� 
pnam 2 o      ���� 0 appname appName 0  3 4 3 r   8 B 5 6 5 n   8 > 7 8 7 1   < >��
�� 
ID   8 4  8 <�� 9
�� 
cwin 9 m   : ;����  6 o      ���� 0 windowid windowID 4  :�� : r   C M ; < ; n   C I = > = 1   G I��
�� 
pnam > 4  C G�� ?
�� 
cwin ? m   E F����  < o      ���� 0 
windowname 
windowName��   , R      ������
�� .ascrerr ****      � ****��  ��   - k   U � @ @  A B A r   U _ C D C n  U [ E F E I   V [�� G���� 0 getwindowid getWindowID G  H�� H o   V W���� 0 appname appName��  ��   F  f   U V D o      ���� 0 windowid windowID B  I�� I Q   ` � J K L J O  c � M N M O  g � O P O O  k � Q R Q r   r � S T S n   r ~ U V U 1   z ~��
�� 
valL V 4   r z�� W
�� 
attr W m   v y X X � Y Y  A X T i t l e T o      ���� 0 
windowname 
windowName R 4   k o�� Z
�� 
cwin Z m   m n����  P o   g h���� 0 frontprocess frontProcess N m   c d [ [�                                                                                  sevs  alis    \  Macintosh HD               �!��BD ����System Events.app                                              �����!��        ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    M a c i n t o s h   H D  -System/Library/CoreServices/System Events.app   / ��   K R      ������
�� .ascrerr ****      � ****��  ��   L r   � � \ ] \ m   � � ^ ^ � _ _   ] o      ���� 0 
windowname 
windowName��   * 5   ' ,�� `��
�� 
capp ` o   ) *���� 0 bundleid bundleID
�� kfrmID  ��  ��   '  a b a l  � � c���� c L   � � d d K   � � e e �� f g�� 0 pid   f o   � ����� 0 	activepid 	activePID g �� h i�� 0 processname processName h o   � ����� 0 
activename 
activeName i �� j k�� 0 appname appName j o   � ����� 0 appname appName k �� l m�� 0 windowid windowID l o   � ����� 0 windowid windowID m �� n���� 0 
windowname 
windowName n o   � ����� 0 
windowname 
windowName��  ��  ��   b  o p o l     ��������  ��  ��   p  q r q l     ��������  ��  ��   r  s t s i      u v u I      �� w���� 0 getwindowid getWindowID w  x�� x o      ���� 0 appname appName��  ��   v k      y y  z { z r      | } | b      ~  ~ b      � � � m      � � � � �H 
 
                                 O b j C . i m p o r t ( ' C o r e G r a p h i c s ' ) ; 
                                 R e f . p r o t o t y p e . $   =   f u n c t i o n ( )   { 
                                         r e t u r n   O b j C . d e e p U n w r a p ( O b j C . c a s t R e f T o O b j e c t ( t h i s ) ) ; 
                                 } 
                                 A p p l i c a t i o n . p r o t o t y p e . g e t W i n d o w L i s t   =   f u n c t i o n ( )   { 
                                         l e t   p i d s   =   A p p l i c a t i o n ( ' c o m . a p p l e . s y s t e m e v e n t s ' ) 
                                         . p r o c e s s e s 
                                         . w h o s e ( 
                                                 { 
                                                         ' b u n d l e I d e n t i f i e r ' :   t h i s . i d ( ) 
                                                 } 
                                         ) . u n i x I d ( ) ; 
                                         r e t u r n     $ . C G W i n d o w L i s t C o p y W i n d o w I n f o ( 
                                                         $ . k C G W i n d o w L i s t E x c l u d e D e s k t o p E l e m e n t s , 
                                                         $ . k C G N u l l W i n d o w I D ) . $ ( ) 
                                                                 . f i l t e r ( x   = >   p i d s . i n d e x O f ( x . k C G W i n d o w O w n e r P I D )   +   1 
                                                               & &   x . k C G W i n d o w L a y e r           = =   0 
                                                               & &   x . k C G W i n d o w S t o r e T y p e   = =   1 
                                                               & &   x . k C G W i n d o w A l p h a           = =   1 
                                         ) . m a p ( x   = >   [ x . k C G W i n d o w N u m b e r ] ) ; 
                                 } 
                                 A p p l i c a t i o n ( ' � o    ���� 0 appname appName  m     � � � � � & ' ) . g e t W i n d o w L i s t ( ) ; } o      ���� 0 js JS {  ��� � L     � � c     � � � l    ����� � n     � � � 4    �� �
�� 
cwor � m    ����  � l    ����� � I   �� ���
�� .sysoexecTEXT���     TEXT � b     � � � m    	 � � � � � 6 o s a s c r i p t   - l   J a v a S c r i p t   - e   � n   	  � � � 1   
 ��
�� 
strq � o   	 
���� 0 js JS��  ��  ��  ��  ��   � m    ��
�� 
long��   t  ��� � l     ��������  ��  ��  ��       �� � � � ��� � � ��� �����������������   � ���������������������������������� 0 getwindowid getWindowID
�� .aevtoappnull  �   � ****�� 0 frontprocess frontProcess�� 0 	activepid 	activePID�� 0 bundleid bundleID�� 0 
activename 
activeName�� 0 appname appName�� 0 windowid windowID�� 0 
windowname 
windowName��  ��  ��  ��  ��  ��  ��   � �� v���� � ����� 0 getwindowid getWindowID�� �� ���  �  ���� 0 appname appName��   � ������ 0 appname appName�� 0 js JS �  � � ���~�}�|
� 
strq
�~ .sysoexecTEXT���     TEXT
�} 
cwor
�| 
long�� �%�%E�O��,%j �k/�& � �{ ��z�y � ��x
�{ .aevtoappnull  �   � **** � k     � � �   � �  & � �  a�w�w  �z  �y   �   �  %�v ��u�t�s�r�q�p�o�n�m�l�k�j�i�h�g�f�e�d�c X�b ^�a�`�_
�v 
prcs �  
�u 
pisf�t 0 frontprocess frontProcess
�s 
idux�r 0 	activepid 	activePID
�q 
bnid�p 0 bundleid bundleID
�o 
pnam�n 0 
activename 
activeName
�m 
capp
�l kfrmID  �k 0 appname appName
�j 
cwin
�i 
ID  �h 0 windowid windowID�g 0 
windowname 
windowName�f  �e  �d 0 getwindowid getWindowID
�c 
attr
�b 
valL�a 0 pid  �` 0 processname processName�_ 
�x �� #*�k/�[�,\Ze81E�O��,E�O��,E�O��,E�UO*���0 g  *�,E�O*�k/�,E` O*�k/�,E` W FX  )�k+ E` O '� � *�k/ *a a /a ,E` UUUW X  a E` UOa �a ���a _ a _ a  �  � �  %�^ �
�^ 
pcap � � � �  i T e r m 2��}� � � � � * c o m . g o o g l e c o d e . i t e r m 2 � � � �  i T e r m 2 � � � � 
 i T e r m�� � � � �  p a s s a t a   ( - z s h )��  ��  ��  ��  ��  ��  ��   ascr  ��ޭ