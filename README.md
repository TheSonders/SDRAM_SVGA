# SDRAM_SVGA
Tests of SVGA and a CPU accessing to a SDRAM  
  
Pruebas de un controlador SDRAM para la memoria MT48LC que incluye las QMTECH.  
El controlador permite el acceso de una gráfica SVGA, leyendo en ráfagas de 8 words de 16bits.  
Para el acceso en lectura/escritura de la CPU, el controlador genera una señal WAIT mientras la memoria está ocupada.  
Genera los comandos AutoRefresh necesarios para la SDRAM durante la señal HSYNC de la SVGA.  
Para las pruebas, he incluído una máquina de estados funcionando como una sencilla CPU a 32MHz.  
La SVGA funciona a 800x600x16bits @ 60Hz, con un pixel clock de 40MHz.  
El controlador y la memoria funcionan a 133,333MHz.  
  
Ahora mismo, la mini-CPU genera unas barras de color para las pruebas, las cuales se ven en pantalla,    
aunque el sintetizado da problemas de timing y aparecen unas finas líneas negras verticales.
