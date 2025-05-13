   ---
   title: "My Book"
   author: "Your Name"
   date: "2025-05-05"
   output:
     bookdown::pdf_document2:
       # Other options
       header-includes:
         - \usepackage{algorithm2e}
   ---
   
      # My First Algorithm

   The following algorithm demonstrates a simple bisection method:

   ```latex
   \begin{algorithm}
   \SetAlgoLined
   \KwIn{Interval $[l, u]$ containing $p^*$, tolerance $\epsilon > 0$}
   \KwOut{Solution $x$}
   \Repeat{$u - l \leq \epsilon$}{
   $t \leftarrow (l + u) / 2$
   \eIf{feasible}{
   $u \leftarrow t$
   } {
   $l \leftarrow t$
   }
   }
   \caption{Bisection Method}
   \end{algorithm}
